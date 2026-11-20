#!/usr/bin/env python3
import re, subprocess, sys
for path in sys.argv[1:]:
    header=subprocess.check_output(["readelf","-h",path],text=True)
    if not re.search(r"Machine:\s+AArch64\b",header):
        raise SystemExit(f"Wrong architecture: {path}")
    data=subprocess.check_output(["readelf","--version-info",path],text=True)
    versions=[tuple(map(int,m)) for m in re.findall(r"GLIBC_(\d+)\.(\d+)",data)]
    if not versions or max(versions)>(2,31):
        raise SystemExit(f"{path}: unacceptable glibc version: {max(versions) if versions else 'missing'}")
    print(path,"max GLIBC",max(versions))
