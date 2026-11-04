#!/usr/bin/env python3
"""Copy a local file dataset into a running Zetaris Docker stack.

Filestore sources in open_data/parquet_csv/table_data/ are read from
/home/zetaris/customer-data/shared/<name>/ inside the engine containers. This
copies a dataset folder there with `docker compose cp`, into every engine
service that reads files (api and driver by default).

  python3 scripts/copy_local_data.py --platform-dir <zetaris-platform-folder>
  python3 scripts/copy_local_data.py --platform-dir <dir> \\
      --src open_data/parquet_csv/table_data/demo_bank --name demo_bank

<zetaris-platform-folder> is the folder holding Zetaris' docker-compose.yml.
A docker cp lasts for the life of the container: after `docker compose down`
or an image upgrade, run it again. Works on Windows, macOS and Linux.
Standard library only; needs Docker with the compose plugin.
"""
import argparse
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_SRC = os.path.join(REPO, "open_data", "parquet_csv", "table_data", "demo_bank")
TARGET_ROOT = "/home/zetaris/customer-data/shared"


def compose(platform_dir, *args, capture=False):
    return subprocess.run(["docker", "compose", *args], cwd=platform_dir, check=True,
                          text=True, capture_output=capture)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--platform-dir", required=True, help="folder with Zetaris' docker-compose.yml")
    p.add_argument("--src", default=DEFAULT_SRC, help="dataset folder to copy (default: demo_bank)")
    p.add_argument("--name", help="folder name under %s (default: last part of --src)" % TARGET_ROOT)
    p.add_argument("--services", default="api,driver", help="comma-separated compose services")
    a = p.parse_args()

    platform_dir = os.path.abspath(a.platform_dir)
    src = os.path.abspath(a.src)
    name = a.name or os.path.basename(src.rstrip("/\\"))
    target = f"{TARGET_ROOT}/{name}"
    services = [s.strip() for s in a.services.split(",") if s.strip()]

    if not os.path.isfile(os.path.join(platform_dir, "docker-compose.yml")):
        sys.exit(f"No docker-compose.yml in {platform_dir}")
    if not os.path.isdir(src):
        sys.exit(f"Dataset folder not found: {src}")

    try:
        for svc in services:
            if not compose(platform_dir, "ps", "-q", svc, capture=True).stdout.strip():
                sys.exit(f"Service '{svc}' is not running. Start Zetaris first: docker compose up -d")
        for svc in services:
            print(f"-> {svc}: copying {src} to {target}")
            compose(platform_dir, "exec", "-T", "-u", "root", svc, "sh", "-c",
                    f"rm -rf '{target}' && mkdir -p '{target}'")
            # "<src>/." copies the folder's contents, not the folder itself
            compose(platform_dir, "cp", os.path.join(src, "."), f"{svc}:{target}")
            compose(platform_dir, "exec", "-T", "-u", "root", svc, "sh", "-c", f"chmod -R a+rX '{target}'")
            n = compose(platform_dir, "exec", "-T", svc, "sh", "-c",
                        f"find '{target}' -type f | wc -l", capture=True).stdout.strip()
            print(f"   {n} files in place")
    except subprocess.CalledProcessError as e:
        sys.exit(f"docker compose failed: {' '.join(e.cmd)}")
    except FileNotFoundError:
        sys.exit("docker not found on PATH")
    print("Done. Now run the dataset's create script (e.g. open_data/parquet_csv/sql/10_demo_bank_create.sql).")


if __name__ == "__main__":
    main()
