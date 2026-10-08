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
regular files without symlinks, bounded sizes (128 MiB ROM, 2 GiB article), and a literal finite/infinite
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
match checked library or previously replayed facts (including kernel-checked
specialization, generalization, and conjunction projection), or be independently
proved by logical simplification or computation. Article-defined CV functions
are evaluated from already proved executable equations using `cv_compute`.
Representation lemmas are not treated as executable equations. It never calls `axiom_in_db`, whose fallback
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
rather than failing during literal loading. An isolated author tracing build now
exports CV computation requests and their proved equations; the unmodified
standard verifier kernel recomputes those requests. The first complete guest
compiler-pass article has independently replayed 7,565 theorems.

The fixed `initProofLibrary` supplies generic compiler, target, semantics, and
CV lemmas. Its local source dependencies are pinned in the trusted-file manifest.
It contains no baseline-specific compilation or Certificate theorem.

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

The full baseline Certificate is proved in HOL. Its complete article package
and positive end-to-end Python verification remain unfinished.

## Author proof export (in progress)

The author uses a separate tracing-kernel checkout at the tested HOL revision:

```sh
python3 tools/prepare_exporter.py --hol-source ../HOL-init-e
python3 tools/test_exporter.py --hol ../HOL-init-e --author-hol ../HOL-init-e-export
python3 tools/build.py --hol ../HOL-init-e initBaselineCertificateTheory initProofLibraryTheory
python3 tools/export_baseline.py --hol ../HOL-init-e --author-hol ../HOL-init-e-export --resume
python3 tools/bind_baseline.py --hol ../HOL-init-e --author-hol ../HOL-init-e-export
python3 tools/package_baseline.py --output /path/to/new-submission
```

`--only THEORY` exports one dependency; `--start-at THEORY` resumes a suffix of
the dependency order. The author patch records proofs, supports CV computation
requests, and emits dictionary cleanup. Exported baseline constants are renamed
into the fresh candidate namespace. Article compaction preserves inference
commands while releasing dictionary objects at their last use. Neither the
patch nor author caches are used to accept a submission. Large CV and byte-list
spines are serialized without ordering every suffix in the writer dictionary.
The exporter reuses the allocation hint from the prior build as data; its full
compiler evaluation still checks the hint before returning bytes.

The smoke regression independently replays fresh definitions, ordinary proof
commands, CV evaluation, and compacted articles. A literal-decoding request is
re-proved with kernel inference rules and matched against the verifier's own
sanitized byte constant. Regression checks reject changed bytes, forged literal
definitions, false results, missing or forged equations, unrelated conclusions, and attempts
to replace fixed constants. Full baseline package assembly, size limits, and
end-to-end performance still need validation before a release.
