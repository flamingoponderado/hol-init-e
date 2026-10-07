# Trusted verifier boundary

Run the verifier from an operator-controlled checkout of the fixed challenge:

```sh
python3 verifier/verify.py /path/to/untrusted-submission
python3 verifier/test_verify.py
```

Participants control only their submission directory. They do not supply or
modify the challenge, verifier, dependency pins, build driver, or trust manifest.
The operator must pin this checkout; hashing files against a manifest inside a
participant-controlled clone would not establish trust.

Current preflight checks the frozen trusted files and CakeML revision, exact
candidate file names, regular files without symlinks, bounded sizes, and a
literal finite/infinite score. It hashes the exact ROM and certificate bytes.
It does not execute participant code, invoke participant build scripts, add
participant directories to HOL's load path, or scan every ROM word as code.
Arbitrary ROM data is permitted; instruction restrictions belong to execution.

The provisional submission envelope is `rom.bin`, `claim.json` containing
`{"K":123}` or `{"K":"infinity"}`, and `certificate.art`. The article is currently
opaque and is never replayed or trusted. Its final proof format is pending.

Exit codes: 1 means rejected preflight; 2 means preflight passed but verification
is incomplete. **There is currently no path returning verified or exit code 0.**
The full fixed HOL4 Certificate and its replay checker are not yet ported.
Additional dispatch metadata and admission checks will follow the fixed challenge.

Before enabling acceptance, implement independent proof replay against the
operator's immutable theory snapshot. Require the exact Certificate proposition
binding ROM, metadata, score, fixed source, and restricted target. Reject extra
axioms, assumptions, alternate constants, and proof steps not supported by that
checker. Candidate Standard ML cannot safely be accepted just by loading it into
HOL and checking a theorem name: it is executable host code. Isolation and
replay are part of the unfinished verifier, not optional participant conventions.

`trusted-files.json` is maintained by challenge authors when releasing a new
fixed challenge. The verifier never regenerates it on a participant's behalf.
