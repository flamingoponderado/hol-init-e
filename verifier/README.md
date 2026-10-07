# Trusted verifier boundary

Run from an operator-controlled checkout of the fixed challenge:

```sh
python3 verifier/verify.py --local /path/to/untrusted-submission --hol /path/to/tested/HOL --progress
python3 verifier/test_verify.py
python3 verifier/test_replay.py
```

The operator pins this checkout and dependencies. Participants control only
`rom.bin`, `claim.json`, and `certificate.art` in a separate submission directory.
A trust manifest supplied by a participant would not establish trust.

`--local` uses the original init-e invocation style and verifies by default.
The same command prepares a missing or stale operator heap before replay,
using `--hol`, `HOLDIR`, or the existing build's HOL path. Submitted files are
frozen before preparation and are not read again afterward.

`--structural-only` explicitly returns `structural_pass` (exit 0) for a valid
envelope without claiming a Certificate proof. The legacy positional interface
still performs preflight unless `--replay` is specified. The original
`--trusted`, `--work`, and `--hide` options are described below.

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
missing/stale prepared verifier. The positional interface without `--replay` never accepts a proof.
`--local` selects full replay automatically; explicit `--structural-only` is a
separate successful envelope check and never returns `verified`.

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

## Original command-line options

The original option names are supported: `--local`, `--trusted`, `--work`,
repeatable `--hide`, `--structural-only`, and `--progress`.

`--trusted` selects the operator-owned HOL port checkout whose manifest,
challenge, dependency pins, checker, and prepared heap are used. It is never
read from a submission. `--work` must name a new directory; it retains frozen
inputs and `replay.log` after success or rejection. Without it, replay uses a
private temporary directory. Structural checks with `--work` retain the
sanitized inputs, but never claim a proof was verified.

`--hide` masks each named file or directory in the replay process using
Bubblewrap. The host filesystem is mounted read-only, the replay workspace is
writable, and the process has private network and PID namespaces. Hidden
directories are empty mounts; hidden file contents are inaccessible (the
replacement may read as empty or be denied by the host mount policy). Overlap with
required verifier, HOL, heap, or workspace paths is rejected. Missing isolation
support or failed sandbox execution rejects verification; masking is never
silently skipped. Structural-only mode executes no participant proof process.

Example:

```sh
python3 verifier/verify.py --local /path/to/submission \
  --trusted /path/to/hol-init-e --work /path/to/new-run \
  --hide /path/to/submission --hide /path/to/private-data --progress
```

The full baseline Certificate and a positive end-to-end replay remain separate
proof obligations; CLI compatibility does not establish them.
