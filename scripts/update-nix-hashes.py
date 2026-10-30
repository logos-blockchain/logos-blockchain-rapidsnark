#!/usr/bin/env python3
# Adds the SRI hashes of a release's archives to rapidsnark-nix-hashes.json, overwriting any existing entry for it.
# Usage: update-nix-hashes.py <version> <dir with rapidsnark-<platform>-<version>.tar.gz files>

import base64, hashlib, json, sys
from pathlib import Path

HASHES_FILE = Path(__file__).resolve().parent.parent / "rapidsnark-nix-hashes.json"

version, archives_dir = sys.argv[1], Path(sys.argv[2])
prefix, suffix = "rapidsnark-", f"-{version}.tar.gz"

hashes = {}
for archive in sorted(archives_dir.glob(f"{prefix}*{suffix}")):
    platform = archive.name[len(prefix):-len(suffix)]
    digest = hashlib.sha256(archive.read_bytes()).digest()
    hashes[platform] = "sha256-" + base64.b64encode(digest).decode()
if not hashes:
    raise SystemExit(f"No archives for {version} in {archives_dir}.")

data = json.loads(HASHES_FILE.read_text())
data[version] = hashes
HASHES_FILE.write_text(json.dumps(data, indent=4, sort_keys=True) + "\n")
print(f"Updated {HASHES_FILE.name} with {version}: {', '.join(hashes)}.")
