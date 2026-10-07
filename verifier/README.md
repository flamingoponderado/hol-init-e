# Trusted verifier boundary

Run from an operator-controlled checkout of the fixed challenge:

```sh
python3 tools/prepare_verifier.py --hol /path/to/tested/HOL
python3 verifier/verify.py /path/to/untrusted-submission --replay
python3 verifier/test_verify.py
python3 verifier/test_replay.py
```

The operator pins this checkout and dependencies. Participants control only
`rom.bin`, `claim.json`, and `certificate.art` in a separate submission directory.
A trust manifest supplied by a participant would not establish trust.

## Frozen literals and the exact statement

The verifier checks trusted-file hashes and the CakeML pin, exact file names,
regular files without symlinks, bounded sizes, and a literal finite/infinite
score. It reads each candidate file once into an immutable snapshot. Later
steps use those frozen bytes rather than reopening candidate paths.

`claim.json` is exactly `{"K":123}` or `{"K":"infinity"}`. The operator's fixed
checker constructs HOL word8 literals from the frozen ROM and a natural-number
or Infinity literal from the sanitized score. It requires exactly:

```text
|- initChallenge.Certificate submissionLiterals.submittedBytes
                             submissionLiterals.submittedScore
```

The certificate existentially quantifies admitted dispatch/layout metadata;
its code field must equal the submitted bytes. The source program, oracle,
restricted target, initial state, evaluator, and admission rules are fixed.
Infinity still requires finite termination for each covered source execution.

No candidate ML, build scripts, or load paths are executed. ROM data is allowed;
instruction restrictions apply when the machine fetches instructions.

## Independent replay

`strictReplayLib.sml` supplies OpenTheory reader callbacks. Axiom requests must
match exact trusted or previously replayed sequents, or be independently proved
as closed computations by `cv_eval`. It never calls `axiom_in_db`, whose fallback
admits a theorem. Definitions may introduce only fresh constants/types in the
operator-created candidate theory. The expected theorem must have no hypotheses
or untrusted theorem tags and must have the exact fixed conclusion.

The replay process uses a private working directory, the hash-checked operator
heap, fixed checker code, time and memory limits, and a completion marker written
only after the exact theorem check. Defaults are 600 seconds and 32 GiB;
`--timeout` and `--memory-gib` configure these limits. The operator must use the
tested HOL revision in `provenance.json`.

Exit codes: **0** verified; **1** rejected; **2** incomplete/preflight only or
missing/stale prepared verifier. Without `--replay`, preflight never accepts.

The fixed proposition and replay path are implemented. A baseline certificate
article and a positive full-certificate replay remain outstanding. Tests include
strict-reader positive examples and a real-process negative test using a valid
article proving an unrelated statement, including a full 904,476-byte literal
ROM. `test_replay.py` checks that this reaches the exact-conclusion rejection
rather than failing during literal loading. HOL's compute primitive is not directly
exported by its OpenTheory writer; computation requests need independent replay.

## Auditable literal preparation

```sh
python3 verifier/verify.py /path/to/candidate --prepare /path/to/new-directory
```

This creates a new mode-0700 directory containing frozen ROM and article bytes,
a regenerated claim, and an audit `submissionLiteralsScript.sml` with decimal
byte and score literals. No candidate text is interpolated into HOL syntax.
Preparation alone returns exit 2. Replay constructs the same literals with HOL
term constructors rather than executing the audit script.

`trusted-files.json` is updated only by challenge authors for a release. The
verifier never regenerates it for a participant. Re-run operator heap preparation
after changing fixed challenge or verifier files.
