#!/usr/bin/env python3
"""Trusted, fail-closed entry point for untrusted hol-init-e submissions.
Preflight is implemented. Proof acceptance is intentionally unavailable until
the complete fixed Certificate and independent proof replay exist.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import stat
import subprocess

ROOT = Path(__file__).resolve().parents[1]
ROM_LIMIT = 128 * 1024 * 1024
PROOF_LIMIT = 16 * 1024 * 1024
FILES = {'rom.bin', 'claim.json', 'certificate.art'}

class Rejected(ValueError): pass

def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result: raise Rejected('duplicate JSON key: '+key)
        result[key] = value
    return result

def inspect_file(directory_fd, name, limit, collect=False):
    """Open once, never follow symlinks, bound reads even if a file grows."""
    fd = os.open(name, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK, dir_fd=directory_fd)
    with os.fdopen(fd, 'rb') as stream:
        info = os.fstat(stream.fileno())
        if not stat.S_ISREG(info.st_mode): raise Rejected(name+' must be a regular file')
        if info.st_size > limit: raise Rejected(name+' exceeds size limit')
        digest, size, chunks = hashlib.sha256(), 0, []
        while chunk := stream.read(min(1024*1024, limit-size+1)):
            size += len(chunk)
            if size > limit: raise Rejected(name+' exceeds size limit')
            digest.update(chunk)
            if collect: chunks.append(chunk)
        return size, digest.hexdigest(), b''.join(chunks)

def preflight(candidate):
    fd = os.open(candidate, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        names = set()
        with os.scandir(fd) as entries:
            for entry in entries:
                if entry.name not in FILES or len(names) >= len(FILES):
                    raise Rejected('unexpected submission entry')
                names.add(entry.name)
        if names != FILES:
            raise Rejected('submission must contain exactly rom.bin, claim.json, certificate.art')
        _, _, claim_bytes = inspect_file(fd, 'claim.json', 65536, True)
        claim = json.loads(claim_bytes, object_pairs_hook=unique_object)
        if not isinstance(claim, dict) or set(claim) != {'K'}:
            raise Rejected('claim.json must have exactly the K field')
        score = claim['K']
        if score != 'infinity' and not (type(score) is int and score >= 0):
            raise Rejected('K must be a nonnegative integer or "infinity"')
        size, digest, _ = inspect_file(fd, 'rom.bin', ROM_LIMIT)
        proof_size, proof_hash, _ = inspect_file(fd, 'certificate.art', PROOF_LIMIT)
        if not proof_size: raise Rejected('certificate.art is empty')
        return {'K': score, 'rom_bytes': size, 'rom_sha256': digest,
                'proof_sha256': proof_hash}
    finally:
        os.close(fd)

def check_trusted():
    manifest = json.loads((ROOT/'verifier/trusted-files.json').read_text())
    for relative, expected in manifest.items():
        path = ROOT/relative
        if path.is_symlink() or not path.is_file():
            raise Rejected('missing or redirected trusted file: '+relative)
        if hashlib.sha256(path.read_bytes()).hexdigest() != expected:
            raise Rejected('modified trusted file: '+relative)
    for directory in ['challenge', 'source']:
        expected_files = {name for name in manifest if name.startswith(directory+'/')}
        observed = set()
        for path in (ROOT/directory).rglob('*'):
            if path.is_symlink(): raise Rejected('redirected trusted path: '+str(path))
            if path.is_file(): observed.add(path.relative_to(ROOT).as_posix())
        if observed != expected_files:
            raise Rejected('unexpected trusted file set in '+directory)
    pin = json.loads((ROOT/'provenance.json').read_text())['cakeml']
    actual = subprocess.check_output(['git', '-C', str(ROOT/'cakeml'), 'rev-parse', 'HEAD'], text=True).strip()
    if actual != pin: raise Rejected('CakeML submodule pin differs')
    dirty = subprocess.check_output(['git', '-C', str(ROOT/'cakeml'), 'status',
                                    '--porcelain', '--untracked-files=all'], text=True)
    if dirty: raise Rejected('CakeML submodule has local changes')

def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('candidate', type=Path)
    args = parser.parse_args(argv)
    try:
        check_trusted()
        report = preflight(args.candidate)
    except (Rejected, OSError, ValueError, RecursionError, subprocess.CalledProcessError) as exc:
        print(json.dumps({'status':'rejected', 'reason':str(exc)}))
        return 1
    print(json.dumps({'status':'incomplete', 'preflight':'passed', **report,
        'reason':'Fixed HOL4 Certificate and independent proof replay are not implemented; no submission is accepted.'}))
    return 2

if __name__ == '__main__': raise SystemExit(main())
