#!/usr/bin/env python3
"""Refuse Linux binaries newer than the Kylin glibc 2.31 ABI."""

import re
import subprocess
import sys
from pathlib import Path

MAX_GLIBC = (2, 31)


def run(*argv: str) -> str:
    proc = subprocess.run(argv, text=True, capture_output=True, check=True)
    return proc.stdout


def check_binary(path: Path) -> None:
    header = run('readelf', '--wide', '--file-header', str(path))
    if not re.search(r'Machine:\s+AArch64\b', header):
        raise RuntimeError(f'{path}: ELF architecture is not AArch64')
    dyn = run('readelf', '--wide', '--dynamic', str(path))
    versions = run('readelf', '--wide', '--version-info', str(path))
    pairs = {
        (int(major), int(minor))
        for major, minor in re.findall(r'\bGLIBC_(\d+)\.(\d+)\b', versions)
    }
    if not pairs:
        raise RuntimeError(f'{path}: no GLIBC version symbols found; investigate before releasing')
    required = max(pairs)
    libs = sorted(set(re.findall(r'Shared library: \[(.*?)\]', dyn)))
    print(f'Binary: {path}')
    print('  Architecture: AArch64')
    print(f'  Maximum required GLIBC: {required[0]}.{required[1]}')
    print('  DT_NEEDED: ' + ', '.join(libs))
    if 'GLIBC_PRIVATE' in versions:
        raise RuntimeError(f'{path}: references GLIBC_PRIVATE')
    if required > MAX_GLIBC:
        raise RuntimeError(f'{path}: requires GLIBC_{required[0]}.{required[1]} > 2.31')
    ldd_output = run('ldd', str(path))
    if 'not found' in ldd_output:
        raise RuntimeError(f'{path}: ldd reports missing linked library: {ldd_output}')
    print('  Linked libraries found on build container: yes')
    print('  GLIBC_2.31 ABI guard: PASS')
    print()


def main() -> int:
    if len(sys.argv) < 2:
        print('usage: verify-compat.py BIN [BIN ...]', file=sys.stderr)
        return 2
    print('PdfCraft Kylin glibc 2.31 compatibility report')
    print('Note: runtime graphics libraries still require device validation.')
    print()
    for arg in sys.argv[1:]:
        check_binary(Path(arg))
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (OSError, subprocess.CalledProcessError, RuntimeError) as exc:
        print(f'Compatibility verification FAILED: {exc}', file=sys.stderr)
        sys.exit(1)
