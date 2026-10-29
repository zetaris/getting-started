"""Build a test package of the object store kit for one partner, and check it for leaks.

    python3 systems/object_stores/scripts/package.py --dry-run    # build in memory, check, print; write nothing
    python3 systems/object_stores/scripts/package.py              # write dist/<name>/ and the ZIP

It reads .env.local (or --env-file). Only these settings shape the package:

    PACKAGE_PARTNER      short name for the ZIP (letters, digits, hyphens), required
    S3_STORE_VENDOR      names baked into the documents and the viewer (optional)
    S3_STORE_PRODUCT
    S3_ADDRESSING        baked into the example env file as the default (optional)
    S3_REGION
    PACKAGE_LOGO         a logo file supplied for this package (optional, never committed)
    PACKAGE_DENY_WORDS   comma-separated words that must not appear anywhere (optional)

Every other value in .env.local (keys, passwords, bucket, endpoint, folder, your
login name, paths) is never copied. It is collected so the build can prove it did
not leak: the build fails, and writes nothing, if any of them appears in any file.

The package keeps the repository's own paths, so every command in the documents
runs the same in a package and in the repository. It holds the kit, the helper
scripts it uses, the SQL for the USL it tests and its sources (resolved from
open_data/manifest.json), and the Zetaris font and logo, unmodified. The same
inputs and date give the same ZIP, byte for byte.
"""

from __future__ import annotations

import argparse
import datetime
import getpass
import hashlib
import io
import json
import re
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
KIT = HERE.parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
sys.path.insert(0, str(HERE))
import onboard  # noqa: E402  (scripts/onboard.py: manifest and dependency order)
import render as renderer  # noqa: E402
import settings_docs as sd  # noqa: E402
import zetaris_sql as z  # noqa: E402

TARGETS = ["sic_edgar_usl"]  # the USL the test builds; its sources come from the manifest
HELPER_SCRIPTS = ["preflight.py", "onboard.py", "run_sql.py", "zetaris_sql.py"]
DOCS = ["docs/guides/zetaris-lightning-sql-commands.md", "docs/guides/zetaris-lightning-sql-companion.md"]
MAINTAINER_SCRIPTS = {"package.py", "settings_docs.py", "check_viewer.py"}  # repository only
ASSETS = {  # website/assets/<from> -> viewer/assets/<to>, copied unmodified
    "fonts/plus-jakarta-sans.ttf": "fonts/plus-jakarta-sans.ttf",
    "fonts/OFL.txt": "fonts/OFL.txt",
    "brand/zetaris-indigo.svg": "brand/zetaris-indigo.svg",
}
RENDERED = {"README.md", "HOWTO.md", "systems/object_stores/viewer/index.html", "systems/object_stores/.env.example"}
FORBIDDEN_NAMES = {".env", ".env.local", ".envrc", ".venv", "__pycache__", ".DS_Store", ".git", ".gitignore"}
FORBIDDEN_SUFFIXES = (".pyc", ".swp", ".swo", "~", ".pem", ".key")
SLUG = re.compile(r"[a-z0-9](?:[a-z0-9-]{0,38}[a-z0-9])?")
REGION = re.compile(r"[a-z0-9-]{2,30}")
MIN_SECRET, MIN_IDENTITY = 6, 5  # shorter values are too likely to match ordinary words
MAX_LOGO = 512 * 1024
HEADER = "Zetaris object store test package"


class BuildError(Exception):
    pass


# --- settings ---------------------------------------------------------------

def read_env(path: Path) -> dict[str, str]:
    """Every NAME=value in the file. The values are not put in os.environ."""
    out: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        v = v.strip()
        if len(v) >= 2 and v[0] == v[-1] and v[0] in "'\"":
            v = v[1:-1]
        out[k.strip()] = v
    return out


class Config:
    """What shapes the package, validated."""

    def __init__(self, env: dict[str, str], partner: str | None, date: datetime.date) -> None:
        self.env = env
        self.partner = (partner or env.get("PACKAGE_PARTNER", "")).strip()
        if not SLUG.fullmatch(self.partner):
            raise BuildError("Set PACKAGE_PARTNER in .env.local (or pass --partner): lowercase letters, digits and hyphens, up to 40 characters.")
        self.date = date
        self.names = {k: env.get(k, "").strip() for k in ("S3_STORE_VENDOR", "S3_STORE_PRODUCT")}
        try:
            self.values = renderer.store_values(self.names["S3_STORE_VENDOR"], self.names["S3_STORE_PRODUCT"])
        except renderer.RenderError as e:
            raise BuildError(str(e)) from e
        self.addressing = env.get("S3_ADDRESSING", "").strip().lower()
        if self.addressing and self.addressing not in ("path", "virtual"):
            raise BuildError("S3_ADDRESSING must be path or virtual.")
        self.region = env.get("S3_REGION", "").strip()
        if self.region and not REGION.fullmatch(self.region):
            raise BuildError("S3_REGION must be lowercase letters, digits and hyphens.")
        self.deny = [w.strip() for w in env.get("PACKAGE_DENY_WORDS", "").split(",") if w.strip()]
        if any(len(w) < 2 for w in self.deny):
            raise BuildError("Each PACKAGE_DENY_WORDS entry must be at least 2 characters.")
        self.logo_path: Path | None = None
        self.logo_bytes = b""
        self.logo_ext = ""
        if env.get("PACKAGE_LOGO", "").strip():
            self._load_logo(Path(env["PACKAGE_LOGO"].strip()).expanduser())

    def _load_logo(self, path: Path) -> None:
        ext = path.suffix.lower()
        if ext not in renderer.LOGO_EXTS:
            raise BuildError(f"PACKAGE_LOGO must be one of {', '.join(renderer.LOGO_EXTS)}.")
        if not path.is_file():
            raise BuildError("PACKAGE_LOGO is set but the file does not exist.")
        data = path.read_bytes()
        if not data or len(data) > MAX_LOGO:
            raise BuildError(f"PACKAGE_LOGO must be between 1 byte and {MAX_LOGO // 1024} KB.")
        head = data[:16]
        magic = {".png": head.startswith(b"\x89PNG"), ".jpg": head.startswith(b"\xff\xd8"), ".jpeg": head.startswith(b"\xff\xd8"),
                 ".webp": head[:4] == b"RIFF" and data[8:12] == b"WEBP", ".svg": b"<svg" in data[:4096].lower()}
        if not magic[ext]:
            raise BuildError(f"PACKAGE_LOGO does not look like a {ext} file.")
        self.logo_path, self.logo_bytes, self.logo_ext = path, data, ".jpg" if ext == ".jpeg" else ext

    @property
    def top(self) -> str:
        return f"zetaris-{self.partner}-object-store-test"

    @property
    def zip_name(self) -> str:
        return f"{self.top}-{self.date:%Y%m%d}.zip"

    @property
    def logo_file(self) -> str | None:
        return f"assets/partner/logo{self.logo_ext}" if self.logo_bytes else None

    @property
    def overrides(self) -> dict[str, str]:
        return {k: v for k, v in {"S3_ADDRESSING": self.addressing, "S3_REGION": self.region, **self.names}.items() if v}


# --- what goes in -----------------------------------------------------------

def read(path: Path) -> bytes:
    return path.read_bytes()


def kit_files() -> dict[str, bytes]:
    """The kit, verbatim: scripts, schema, issues, the viewer template and its fixture."""
    out: dict[str, bytes] = {}
    base = "systems/object_stores/"
    for rel in ("README.md", "requirements.txt", "settings.json"):
        out[base + rel] = read(KIT / rel)
    for p in sorted((KIT / "scripts").glob("*.py")):
        if p.name not in MAINTAINER_SCRIPTS:
            out[base + "scripts/" + p.name] = read(p)
    for p in sorted((KIT / "issues").glob("*.md")):
        out[base + "issues/" + p.name] = read(p)
    out[base + "viewer/index.html.tmpl"] = read(KIT / "viewer" / "index.html.tmpl")
    for p in sorted((KIT / "viewer" / "fixtures").glob("*")):
        out[base + "viewer/fixtures/" + p.name] = read(p)
    return out


def sources_files() -> dict[str, bytes]:
    """The SQL for the target USL and everything it requires, with a manifest
    that lists exactly those (so onboard.py --check passes in the package)."""
    sources = onboard.load_manifest()
    order = onboard.resolve(sources, TARGETS)
    out: dict[str, bytes] = {}
    entries = []
    for sid in order:
        src = sources[sid]
        if src.get("status") == "known_to_fail":
            raise BuildError(f"{sid} is known to fail; it cannot be in a package.")
        entries.append(src)
        script = ROOT / src["script"]
        out[src["script"]] = read(script)
        select = script.with_name(script.name.replace("_create.sql", "_select.sql"))
        if select.is_file() and select != script:
            out[select.relative_to(ROOT).as_posix()] = read(select)
    manifest = json.loads((ROOT / "open_data" / "manifest.json").read_text(encoding="utf-8"))
    manifest["sources"] = entries
    out["open_data/manifest.json"] = (json.dumps(manifest, indent=2, ensure_ascii=False) + "\n").encode()
    return out


def build_files(cfg: Config) -> dict[str, bytes]:
    files: dict[str, bytes] = {}
    files.update(kit_files())
    files.update(sources_files())
    for name in HELPER_SCRIPTS:
        files["scripts/" + name] = read(ROOT / "scripts" / name)
    for rel in DOCS:
        files[rel] = read(ROOT / rel)
    for src, dst in ASSETS.items():
        files["systems/object_stores/viewer/assets/" + dst] = read(ROOT / "website" / "assets" / src)
    if cfg.logo_bytes:
        files["systems/object_stores/viewer/assets/partner/logo" + cfg.logo_ext] = cfg.logo_bytes
    try:
        for tmpl, dest in (("HOWTO.md.tmpl", "HOWTO.md"), ("PACKAGE_README.md.tmpl", "README.md")):
            files[dest] = renderer.render((KIT / tmpl).read_text(encoding="utf-8"), cfg.values).encode()
        files["systems/object_stores/viewer/index.html"] = renderer.render_viewer(KIT / "viewer" / "index.html.tmpl", cfg.names, cfg.logo_file).encode()
    except renderer.RenderError as e:
        raise BuildError(f"a template did not render: {e}") from e
    files["systems/object_stores/.env.example"] = sd.env_example(sd.load(), cfg.overrides).encode()
    files["MANIFEST.txt"] = manifest_text(cfg, files).encode()
    files["SHA256SUMS"] = "".join(f"{hashlib.sha256(files[n]).hexdigest()}  {n}\n" for n in sorted(files)).encode()
    return files


def git_state() -> str:
    try:
        head = subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, capture_output=True, text=True, timeout=10).stdout.strip()
        dirty = subprocess.run(["git", "status", "--porcelain", "--", "systems", "scripts", "open_data", "docs/guides", "website/assets"],
                               cwd=ROOT, capture_output=True, text=True, timeout=10).stdout.strip()
        return f"{head} ({'with uncommitted changes' if dirty else 'clean'})" if head else "unknown"
    except (OSError, subprocess.SubprocessError):
        return "unknown"


def manifest_text(cfg: Config, files: dict[str, bytes]) -> str:
    lines = [HEADER, f"Built by systems/object_stores/scripts/package.py on {cfg.date:%Y-%m-%d}",
             f"Partner: {cfg.partner}", f"Object store: {cfg.values['STORE_NAME']}", f"Source: {git_state()}",
             f"Files: {len(files) + 2} (including this file and SHA256SUMS)", "", "Contents:"]
    lines += [f"  {len(files[n]):>9,}  {n}" for n in sorted(files)]
    return "\n".join(lines) + "\n"


# --- the leak check ---------------------------------------------------------

def forbidden_values(env: dict[str, str], schema: dict, cfg: Config) -> tuple[list[tuple[str, str]], list[str]]:
    """Values that must not appear anywhere: every value in .env.local that is not
    allowed to be baked, plus the login name and home folder. Returns the list and
    the names skipped because they are too short to check reliably."""
    defaults = {s["name"]: (s["default"] or "") for s in schema["settings"]}
    bake = {s["name"] for s in schema["settings"] if s.get("bake")}
    skip_names = bake | {"PACKAGE_PARTNER", "PACKAGE_DENY_WORDS"}
    found: list[tuple[str, str]] = []
    short: list[str] = []

    def add(label: str, value: str, minimum: int) -> None:
        value = value.strip()
        if not value:
            return
        if len(value) < minimum:
            short.append(label)
        elif (label, value) not in found:
            found.append((label, value))

    for name, value in env.items():
        if name in skip_names or value == defaults.get(name, None):
            continue
        add(name, value, MIN_SECRET if next((s["secret"] for s in schema["settings"] if s["name"] == name), True) else MIN_IDENTITY)
    endpoint = env.get("S3_ENDPOINT_URL", "")
    if endpoint:
        add("S3_ENDPOINT_URL (host)", re.sub(r"^https?://", "", endpoint).split("/")[0].split(":")[0], MIN_IDENTITY)
    for m in re.findall(r"[\w.+-]+@[\w.-]+\.\w+", env.get("ZETARIS_USER_AGENT", "")):
        add("ZETARIS_USER_AGENT (email)", m, MIN_IDENTITY)
    try:
        add("your login name", getpass.getuser(), MIN_IDENTITY)
    except Exception:  # noqa: BLE001
        pass
    add("your home folder", str(Path.home()), MIN_IDENTITY)
    return found, sorted(set(short))


def leak_check(files: dict[str, bytes], values: list[tuple[str, str]], deny: list[str]) -> list[str]:
    """Problems found in the files, as text that never contains a secret value."""
    problems: list[str] = []
    for name in sorted(files):
        parts = name.split("/")
        if any(p in FORBIDDEN_NAMES for p in parts) or name.endswith(FORBIDDEN_SUFFIXES):
            problems.append(f"{name}: a file that must never be in a package")
        data = files[name]
        low = data.lower()
        for label, value in values:
            if value.encode() in data:
                problems.append(f"{name}: contains the value of {label}")
        for word in deny:
            if word.lower().encode() in low:
                problems.append(f"{name}: contains the denied word {word!r}")
        if name in RENDERED:
            text = data.decode("utf-8", "replace")
            if "{{" in text or "<!--include:" in text or renderer.PARTNER_MARK in text:
                problems.append(f"{name}: an unresolved template token is left")
    return problems


# --- output -----------------------------------------------------------------

def zip_bytes(files: dict[str, bytes], cfg: Config) -> bytes:
    """A ZIP whose bytes depend only on the files and the date."""
    stamp = (cfg.date.year, cfg.date.month, cfg.date.day, 0, 0, 0)
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as zf:
        for name in sorted(files):
            info = zipfile.ZipInfo(f"{cfg.top}/{name}", date_time=stamp)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = 0o644 << 16
            zf.writestr(info, files[name])
    return buf.getvalue()


def read_back(data: bytes, cfg: Config) -> dict[str, bytes]:
    """The files in a ZIP, with the top folder removed."""
    out: dict[str, bytes] = {}
    with zipfile.ZipFile(io.BytesIO(data)) as zf:
        bad = zf.testzip()
        if bad:
            raise BuildError(f"the ZIP failed its own integrity check at {bad}")
        for info in zf.infolist():
            if not info.filename.startswith(cfg.top + "/"):
                raise BuildError(f"unexpected entry in the ZIP: {info.filename}")
            out[info.filename[len(cfg.top) + 1:]] = zf.read(info)
    return out


def write_tree(files: dict[str, bytes], dest: Path) -> None:
    marker = dest / "MANIFEST.txt"
    if dest.exists():
        if not (marker.is_file() and marker.read_text(encoding="utf-8", errors="replace").startswith(HEADER)):
            raise BuildError(f"{dest} exists and was not built by this script; move it away first.")
        shutil.rmtree(dest)
    for name, data in files.items():
        target = dest / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)


def build(env: dict[str, str], partner: str | None, date: datetime.date, out_dir: Path, dry_run: bool, log=print) -> int:
    schema = sd.load()
    problems = sd.validate(schema)
    if problems:
        raise BuildError("settings.json has problems: " + "; ".join(problems))
    cfg = Config(env, partner, date)
    files = build_files(cfg)
    values, short = forbidden_values(env, schema, cfg)
    found = leak_check(files, values, cfg.deny)
    zdata = zip_bytes(files, cfg)
    found += [f"(ZIP) {p}" for p in leak_check(read_back(zdata, cfg), values, cfg.deny)]

    log(f"Package    {cfg.top}  ({cfg.date:%Y-%m-%d})")
    log(f"Store      {cfg.values['STORE_NAME']}")
    log(f"Baked      " + (", ".join(f"{k}={v}" for k, v in cfg.overrides.items() if k not in ("S3_STORE_VENDOR", "S3_STORE_PRODUCT")) or "no addressing or region override")
        + (f"; logo {cfg.logo_ext}" if cfg.logo_bytes else ""))
    log(f"Files      {len(files)}, {sum(len(v) for v in files.values()) / 1024:,.0f} KB; ZIP {len(zdata) / 1024:,.0f} KB")
    log(f"Checked    {len(values)} value(s) from .env.local and {len(cfg.deny)} denied word(s) against every file and the ZIP")
    if short:
        log(f"Skipped    too short to check reliably: {', '.join(short)}")
    if found:
        log("\nLEAK CHECK FAILED. Nothing was written.")
        for p in found:
            log("  " + p)
        return 1
    log("Leak check passed.")
    if dry_run:
        log("\nDry run: nothing was written. Files:")
        for n in sorted(files):
            log(f"  {len(files[n]):>9,}  {n}")
        return 0

    out_dir.mkdir(parents=True, exist_ok=True)
    tree, zpath = out_dir / cfg.top, out_dir / cfg.zip_name
    write_tree(files, tree)
    zpath.write_bytes(zdata)
    again = leak_check(read_back(zpath.read_bytes(), cfg), values, cfg.deny)
    if again:  # defense in depth: the file on disk, not just the bytes in memory
        zpath.unlink()
        shutil.rmtree(tree, ignore_errors=True)
        log("\nLEAK CHECK FAILED on the written ZIP; it was deleted.")
        for p in again:
            log("  " + p)
        return 1
    log(f"\nWrote      {tree}/")
    log(f"Wrote      {zpath}")
    log(f"SHA-256    {hashlib.sha256(zdata).hexdigest()}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0], formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--env-file", help="settings file (default: .env.local in the repository root or top-level checkout)")
    ap.add_argument("--partner", help="override PACKAGE_PARTNER")
    ap.add_argument("--date", help="build date YYYYMMDD (default: today); the same date gives the same ZIP")
    ap.add_argument("--out", default=str(ROOT / "dist"), help="output folder (default: dist/)")
    ap.add_argument("--dry-run", action="store_true", help="build and check in memory, write nothing")
    a = ap.parse_args()
    env_file = Path(a.env_file) if a.env_file else next((p for p in z.env_file_candidates() if p.is_file()), None)
    if not env_file or not env_file.is_file():
        print("No .env.local found. Create one, or pass --env-file.", file=sys.stderr)
        return 2
    try:
        date = datetime.datetime.strptime(a.date, "%Y%m%d").date() if a.date else datetime.date.today()
        print(f"Settings   {env_file}")
        return build(read_env(env_file), a.partner, date, Path(a.out), a.dry_run)
    except (BuildError, ValueError) as e:
        print(f"Cannot build: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
