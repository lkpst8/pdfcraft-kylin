#!/usr/bin/env python3
import re, subprocess, sys
for path in sys.argv[1:]:
    header = subprocess.check_output(["file",path],text=True)
    if "aarch64" not in header.lower() and "arm aarch64" not in header.lower():
        raise SystemExit(f"Wrong architecture: {path}: {header}")
    data = subprocess.check_output(["readelf","--version-info",path],text=True)
    versions = sorted(set(tuple(map(int,m.groups())) for m in re.finditer(r"GLIBC_(\\d+)\\.(\\d+)",data)))
    if versions and max(versions) > (2,31):
        raise SystemExit(f"{path}: incompatible GLIBC_{max(versions)}")
    print(path, "maximum GLIBC", max(versions) if versions else "none")
