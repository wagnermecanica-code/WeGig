#!/usr/bin/env python3
"""Fail if a publication directory or app archive contains a .p8 entry."""

import sys
import zipfile
from pathlib import Path


def check(path):
    if not path.exists():
        raise ValueError(f'Expected publication artifact is missing: {path}')
    if path.suffix.lower() == '.p8':
        raise ValueError(f'Private key file blocked: {path}')
    if path.is_dir():
        for entry in path.rglob('*'):
            if entry.suffix.lower() == '.p8':
                raise ValueError(f'Private key file blocked: {entry}')
            if entry.is_file() and entry.suffix.lower() in {'.ipa', '.apk', '.aab', '.zip'}:
                check(entry)
    elif path.suffix.lower() in {'.ipa', '.apk', '.aab', '.zip'}:
        with zipfile.ZipFile(path) as archive:
            for entry in archive.namelist():
                if Path(entry.rstrip('/')).suffix.lower() == '.p8':
                    raise ValueError(f'Private key file blocked: {path}!{entry}')
    else:
        raise ValueError(f'Unsupported publication artifact: {path}')


if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit('Expected at least one publication artifact')
    try:
        for arg in sys.argv[1:]:
            check(Path(arg))
    except (OSError, ValueError, zipfile.BadZipFile) as error:
        sys.exit(str(error))