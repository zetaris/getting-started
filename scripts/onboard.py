#!/usr/bin/env python3
"""Onboard one or more sources, running whatever they depend on first.

    python3 scripts/onboard.py --list
    python3 scripts/onboard.py --check
    python3 scripts/onboard.py plan sic_edgar_usl
    python3 scripts/onboard.py run edgar_profiles --dry-run
    python3 scripts/onboard.py run company_dns pokeapi --skip-exists

Sources and their dependencies are declared once, in open_data/manifest.json
(`requires` lists the source ids that must exist first). This tool resolves the
order, shows it, and runs each create script with scripts/run_sql.py's engine.
Data sources and USL models are handled the same way: a USL model simply
`requires` the sources it activates from.

Create scripts change the instance. Use `plan` or `--dry-run` first.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import zetaris_sql as z  # noqa: E402

MANIFEST = z.ROOT / "open_data" / "manifest.json"
STATUSES = {"verified", "unverified", "known_to_fail"}
KINDS = {"rest", "filestore", "usl"}


def load_manifest(path: Path = MANIFEST) -> dict[str, dict]:
    data = json.loads(path.read_text(encoding="utf-8"))
    sources: dict[str, dict] = {}
    for src in data["sources"]:
        if src["id"] in sources:
            raise z.ZetarisError(f"Duplicate source id in manifest: {src['id']}")
        sources[src["id"]] = src
    return sources


def check(sources: dict[str, dict]) -> list[str]:
    """Problems with the manifest: missing files, unknown ids, bad values, cycles."""
    problems: list[str] = []
    for sid, src in sources.items():
        if src.get("kind") not in KINDS:
            problems.append(f"{sid}: kind must be one of {sorted(KINDS)}")
        if src.get("status") not in STATUSES:
            problems.append(f"{sid}: status must be one of {sorted(STATUSES)}")
        if not (z.ROOT / src["script"]).is_file():
            problems.append(f"{sid}: script not found: {src['script']}")
        for dep in src.get("requires", []):
            if dep not in sources:
                problems.append(f"{sid}: requires unknown source '{dep}'")
    if not problems:
        try:
            resolve(sources, list(sources))
        except z.ZetarisError as e:
            problems.append(str(e))
    listed = {Path(s["script"]).resolve() for s in sources.values()}
    for path in sorted((z.ROOT / "open_data").glob("**/*_create.sql")):
        if path.resolve() not in listed:
            problems.append(f"not in manifest: {path.relative_to(z.ROOT)}")
    return problems


def resolve(sources: dict[str, dict], targets: list[str]) -> list[str]:
    """Dependency-first order for the targets, each source once."""
    order: list[str] = []
    state: dict[str, int] = {}  # 1 = visiting, 2 = done

    def visit(sid: str, trail: list[str]) -> None:
        if sid not in sources:
            raise z.ZetarisError(f"Unknown source '{sid}'. Run with --list to see the ids.")
        if state.get(sid) == 2:
            return
        if state.get(sid) == 1:
            raise z.ZetarisError("Dependency cycle: " + " -> ".join(trail + [sid]))
        state[sid] = 1
        for dep in sources[sid].get("requires", []):
            visit(dep, trail + [sid])
        state[sid] = 2
        order.append(sid)

    for t in targets:
        visit(t, [])
    return order


def user_agent_needed(src: dict) -> bool:
    return z.PLACEHOLDER_UA in (z.ROOT / src["script"]).read_text(encoding="utf-8")


def print_plan(sources: dict[str, dict], order: list[str], targets: list[str]) -> None:
    for i, sid in enumerate(order, 1):
        src = sources[sid]
        notes = []
        if sid not in targets:
            notes.append("dependency")
        if src["status"] != "verified":
            notes.append(src["status"].replace("_", " "))
        if user_agent_needed(src):
            notes.append("needs ZETARIS_USER_AGENT")
        extra = f"  [{', '.join(notes)}]" if notes else ""
        print(f"{i:>2}. {sid:<22} {src['kind']:<9} {src['script']}{extra}")


def cmd_list(sources: dict[str, dict]) -> int:
    print(f"{'id':<22} {'kind':<9} {'status':<14} requires")
    for sid, src in sources.items():
        print(f"{sid:<22} {src['kind']:<9} {src['status']:<14} {', '.join(src.get('requires', [])) or '-'}")
        print(f"{'':<22} {src['summary']}")
    return 0


def cmd_run(args, sources: dict[str, dict]) -> int:
    targets = args.sources
    order = targets[:] if args.no_deps else resolve(sources, targets)
    for t in targets:
        resolve(sources, [t])  # validates ids
    bad = [s for s in order if sources[s]["status"] == "known_to_fail" and s in targets]
    if bad and not args.allow_known_to_fail:
        raise z.ZetarisError(
            f"{', '.join(bad)} is marked known_to_fail (see its known_to_fail/ write-up). "
            "Pass --allow-known-to-fail to run it anyway."
        )
    print_plan(sources, order, targets)
    if args.dry_run:
        print("(dry run: nothing sent)")

    env = z.load_env(args.env_file)
    prepared: list[tuple[str, list[str]]] = []
    for sid in order:
        text = (z.ROOT / sources[sid]["script"]).read_text(encoding="utf-8")
        stmts = z.split_statements(text)
        try:
            stmts = z.apply_user_agent(stmts)
        except z.ZetarisError as e:
            if not args.dry_run:
                raise z.ZetarisError(f"{sid}: {e}") from e
            print(f"warning: {sid}: {e}", file=sys.stderr)
        prepared.append((sid, stmts))
    if args.dry_run:
        return 0

    z.reexec_in_venv_if_needed(args.channel)
    channel = z.open_channel(args.channel, args.jar)
    print(f"\nchannel={args.channel} env={env or 'process environment'}")
    try:
        for sid, stmts in prepared:
            is_dep = sid not in targets
            # A dependency that already exists is satisfied, so duplicates are skipped for
            # dependencies; the requested targets only skip when --skip-exists is given.
            skip = args.skip_exists or is_dep
            print(f"\n=== {sid} ({len(stmts)} statements{', dependency' if is_dep else ''})")
            ok = skipped = 0
            for i, stmt in enumerate(stmts, 1):
                label = " ".join(stmt.split())[:90]
                try:
                    channel.run(stmt, limit=args.limit)
                    ok += 1
                    print(f"{i:>3}. ok       {label}")
                except z.ZetarisError as e:
                    if skip and z.ALREADY_EXISTS.search(str(e)):
                        skipped += 1
                        print(f"{i:>3}. exists   {label}")
                        continue
                    print(f"{i:>3}. ERROR    {label}\n     {e}", file=sys.stderr)
                    print(f"\nSTOPPED in {sid} at statement {i}. Later sources were not run.", file=sys.stderr)
                    return 1
            print(f"    {ok} ok" + (f", {skipped} already existed" if skipped else ""))
    finally:
        channel.close()
    print("\ndone")
    return 0


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--list", action="store_true", help="list every source, its status and dependencies")
    p.add_argument("--check", action="store_true", help="validate the manifest against the repo")
    p.add_argument("command", nargs="?", choices=["plan", "run"])
    p.add_argument("sources", nargs="*", help="source ids (see --list)")
    p.add_argument("--channel", choices=["rest", "jdbc"], default="rest")
    p.add_argument("--jar", help="JDBC driver JAR (or set ZETARIS_JDBC_JAR)")
    p.add_argument("--env-file", help="env file to load")
    p.add_argument("--dry-run", action="store_true", help="show the plan and statement counts without connecting")
    p.add_argument("--skip-exists", action="store_true", help="skip 'already exists' errors on the requested sources too (dependencies always do)")
    p.add_argument("--no-deps", action="store_true", help="run only the named sources, not their dependencies")
    p.add_argument("--allow-known-to-fail", action="store_true")
    p.add_argument("--limit", type=int, default=20)
    args = p.parse_args()

    try:
        sources = load_manifest()
        if args.check:
            problems = check(sources)
            for pr in problems:
                print("PROBLEM:", pr)
            print("manifest ok" if not problems else f"{len(problems)} problem(s)")
            return 1 if problems else 0
        if args.list:
            return cmd_list(sources)
        if not args.command or not args.sources:
            p.error("give `plan <id>...` or `run <id>...` (or --list / --check)")
        if args.command == "plan":
            order = resolve(sources, args.sources)
            print_plan(sources, order, args.sources)
            return 0
        return cmd_run(args, sources)
    except (z.ZetarisError, OSError, KeyError, json.JSONDecodeError) as e:
        print(f"error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
