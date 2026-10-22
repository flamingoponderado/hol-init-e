# Trusted verifier and submission protocol

Run from an operator-controlled checkout of the fixed challenge:

```sh
python3 verifier/verify.py /path/to/source-submission \
  --hol /path/to/tested/HOL --author-hol /path/to/tracing/HOL \
  --work /path/to/new-work-directory
python3 verifier/test_verify.py
python3 verifier/test_replay.py
```

This source envelope is the only participant submission format. It contains
`rom.bin`, `claim.json`, and flat `.sml`/`.sig` files under `experiments/`.
Participants do not supply an OpenTheory article. The operator pins this
checkout and dependencies; a trust manifest supplied by a participant does not
establish trust.

The participant-facing command freezes all inputs and checks trusted-file
hashes before running source. It then builds and exports the proof in an
isolated author HOL process and sends the generated article to a separate
strict-replay function. Exit 0 with `status: verified` requires exact
`Certificate` replay. Article files and the article checker are internal
intermediates, not an alternate submission path.

## Frozen literals and the exact statement

The source verifier checks trusted-file hashes and the CakeML pin, exact file
names, regular files without symlinks, bounded sizes (128 MiB ROM, 64 MiB total
proof source), and a literal finite/infinite score. It reads each candidate
file once into an immutable snapshot. Later steps use those frozen bytes.

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

The source pipeline executes participant proof scripts only in the isolated
author process described below. Strict replay executes no candidate ML or build
scripts. ROM bytes are data; instruction restrictions apply when the machine
fetches instructions.

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

The complete baseline article package passes the production Python verifier
with the exact fixed Certificate conclusion and frozen ROM/score literals.
The [verification record](../artifacts/baseline/verification.json) records exit 0,
`status: verified`, the 950,344-byte ROM, Infinity score, and artifact hashes.
Tests include
strict-reader positive examples and a real-process negative test using a valid
article proving an unrelated statement, including a full 904,616-byte literal
ROM. `test_replay.py` checks that this reaches the exact-conclusion rejection
rather than failing during literal loading. An isolated author tracing build now
exports CV computation requests and their proved equations; the unmodified
standard verifier kernel recomputes those requests. For the prior guest, the exact first nine compiler articles selected for its package independently
replay 13,399 exported theorems in one fresh standard-kernel process, using only
the fixed library and preceding proof data. This includes full native bytecode
compilation. The measured run took 679.5 seconds and peaked at 52.7 GiB RSS,
so the baseline requires explicit limits above the defaults. The successful
full-package run (PR25 v4) took 8,727 seconds and peaked at 90.54 GiB child RSS,
using `--timeout 10800 --memory-gib 112`. Reduced Lean decoder/step agreement
remains an independent, unproved semantic obligation.

## Source submission pipeline

Use the single participant command at the top of this document. The separate
`verify_source.py` module is an implementation detail, not a second interface.
The source envelope contains exactly `rom.bin`, `claim.json`, and `experiments/`
with flat `.sml`/`.sig` proof-source files.

The verifier freezes the source files, builds the candidate proof with one
author-side HOL worker in Bubblewrap (read-only host filesystem, private PID
and network namespaces, and resource limits), and generates the OpenTheory
article locally. The verifier then invokes the strict article checker as an
internal function, with the generated ROM and claim. Only a separate, fresh,
operator-owned strict kernel replay can return `verified`; source execution,
article generation, and `--generate-only` never count as proof acceptance.
The source bundle replaces the large article on the wire while retaining the
exact frozen-ROM/score Certificate check. This currently targets the baseline
`initBaselineCertificate` proof-source layout; it does not change the fixed
challenge proposition.

The source verifier requires the tested standard HOL tree, a distinct tracing
author HOL tree prepared for export, CakeML at the pinned submodule revision,
and Bubblewrap. It keeps generated sources, article, and replay evidence under
the requested work directory.

The fixed `initProofLibrary` supplies generic compiler, target, semantics, and
CV lemmas. Its local source dependencies are pinned in the trusted-file manifest.
It contains no baseline-specific compilation or Certificate theorem.

## Internal strict replay

The article replay implementation operates only on the generated package
inside the source pipeline. It freezes ROM and score bytes, constructs HOL
literals without interpolating candidate text, and requires the exact fixed
conclusion. The article replay parser is not exposed as a participant command.

`trusted-files.json` is updated only by challenge authors for a release. The
verifier never regenerates it for a participant. Re-run operator heap preparation
after changing fixed challenge or verifier files.

The generated article is bounded to 3 GiB and receives strict replay resource
limits. Historical full-article replay evidence used `--timeout 10800
--memory-gib 112`; the source command exposes replay limits and separate
author-side limits.

## Author proof export

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
the dependency order. `--stop-before THEORY` bounds a suffix for separate
export batches. Workers default to a 24 GiB Poly/ML heap limit and one GC thread;
`--maxheap-mib` and `--gc-threads` adjust these author resource settings.
The author patch records proofs, supports CV computation
requests, and emits dictionary cleanup. Exported baseline constants are renamed
into the fresh candidate namespace. Article compaction preserves inference
commands while releasing dictionary objects at their last use. Neither the
patch nor author caches are used to accept a submission. Large CV and byte-list
spines are serialized without ordering every suffix in the writer dictionary.
The exporter reuses the allocation hint from the prior build as data; its full
compiler evaluation still checks the hint before returning bytes. Large literal
conversions use independently recomputed evaluation requests. The suffix exporter
records shared helper proofs and solved instruction goals separately, then clears
its temporary dictionary before continuing the final conjunction proof.

The smoke regression independently replays fresh definitions, ordinary proof
commands, CV evaluation, and compacted articles. A literal-decoding request is
re-proved with kernel inference rules and matched against the verifier's own
sanitized byte constant. Fixed-vocabulary `EVAL` requests are also recomputed by
the standard kernel; this path rejects candidate-defined constants. Propositional
congruence requests are discharged with HOL’s tautology prover. The lookup set
includes exactly HOL’s four foundational axioms (`BOOL_CASES_AX`, `ETA_AX`,
`SELECT_AX`, `INFINITY_AX`) alongside the fixed library theorems. Regression
checks reject changed bytes, forged literal
definitions, false results, missing or forged equations, unrelated conclusions, and attempts
to replace fixed constants. The full baseline package has passed production
verification; its result, resource use, and hashes are recorded in
[verification.json](../artifacts/baseline/verification.json).


### Parallel article diagnostics

To locate replay gaps without repeatedly processing the full compiler prefix:

```sh
python3 tools/audit_articles.py --list
python3 tools/audit_articles.py --workers 3 --heap-gib 24 --resume \
  initBootstrapSuffixSteps initBootstrapChallengeSuffixSteps initBaselineCertificate
```

With no module names, the tool checks all modules in the export plan. Each worker
loads built predecessor theories, introduces the selected article's definitions
in a fresh candidate theory, and checks that article's commands. The runner
uses compiled theory parent metadata and records separate logs and results under
`.export-baseline-checkpoint/audit/`. Successful results are reused only when
the recorded input fingerprints match. Failures in one article do not stop
the other workers.

These are author diagnostics, **not submission verification**: predecessor
theorems are imported instead of reconstructed from the submitted article, and
the loaded datatype metadata can differ from a fresh full replay. The diagnostic
evaluation guard also excludes mapped predecessor constants, preserving the
production restriction on evaluating candidate definitions. Only the complete
`verifier/verify.py` run checks the package from the fixed trust root and binds
its conclusion to the frozen bytecode and score.
