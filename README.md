# hol-init-e

An experimental port of the [init-e challenge](https://github.com/flamingoponderado/init-e).
Participants submit arbitrary RISC-V bytes; the fixed guest, supported target
instructions, observations, and execution budget define the challenge.
CakeML's Pancake compiler supplies one route to a baseline submission.

The experiment replaces generated Lean computation certificates with HOL4
`cv_compute` evaluations. The generated Lean proof tree is not imported.
HOL has proved that the full top-level Pancake compilation returns the
904,476-byte native RISC-V artifact. The fixed challenge evaluator also has a
checked finite bootstrap execution to native entry, and the resulting ordinary
memory agrees with the fixed source state.
**A complete baseline challenge certificate is not yet proved.** Native code
alone is not a bootstrapped challenge submission.

## Fixed challenge and untrusted submissions

`challenge/`, `source/`, dependency pins, and `verifier/` belong to the challenge
operator. Participants supply a separate submission directory; they cannot
replace the challenge or certificate proposition. `experiments/` is baseline
compiler development and grants no additional participant authority.

```sh
python3 verifier/verify.py /path/to/submission
python3 verifier/test_verify.py
```

The verifier checks trusted-file hashes and the CakeML pin before inspecting
candidate files. It never executes candidate ML. Preflight success returns **incomplete (exit 2)**. With `--replay`, the verifier
uses an operator-prepared HOL heap and accepts only a closed proof of the exact
fixed `initChallenge.Certificate submittedBytes submittedScore`. See
[the verifier boundary](verifier/README.md) and [submission format](submission/README.md).

## Included

- CakeML as a pinned `cakeml/` submodule. The separate sibling checkout is
  independent and is not a build dependency.
- The complete literal guest AST, translated to `64 panLang$decl list` from
  init-e's authoritative `Guest/Ast.lean`, plus the readable preprocessed source.
- The finite/infinite score model and memory-layout constants and proofs.
  Infinity still requires a finite terminating execution for every covered input.
- A restricted instruction decoder and machine step. Unsupported fetched
  encodings become `UnknownInstruction`; compressed decoding always does so.
  There is no blanket requirement that every byte in a submitted ROM be code.
- The declared gas-limit reader and covered-outcome/output comparison rules.
- Fixed source state, machine startup, framing, shared memory, accelerator
  oracle, submission admission, and challenge certificate definitions.
- Frozen submission snapshots, regenerated ROM/score literals, and a strict
  proof-replay component with tampering tests.
- All Pancake frontend passes and the RISC-V backend translated to cv equations.
  Native register allocation supplies an untrusted hint checked by HOL.
- Resource-limited certificate replay from frozen bytes and sanitized score
  literals, with exact conclusion, assumption, and theorem-tag checks.

## Build

Use Poly/ML and a built HOL4 checkout with `cv_transLib`. Revisions and source
hashes are in `provenance.json`. No Lean installation is needed for the build.

```sh
git submodule update --init
python3 tools/build.py --hol /path/to/HOL
python3 tools/test_import_ast.py
```

With HOL at `../HOL`, the `--hol` argument may be omitted. `HOLDIR` also works.
The build driver creates an ignored `.build/` source view linking the needed
CakeML and project files. This avoids unrelated upstream heap/bootstrap targets
and gives dependency discovery a common search path. It does not edit CakeML.
Use the same HOL checkout for successive builds of that directory.

To reproduce the AST from the pinned init-e checkout:

```sh
python3 tools/import_ast.py /path/to/init-e/Guest/Ast.lean --check
```

The importer checks the entire input hash and rejects unknown syntax and
constructors. Its output is checked as HOL definitions, but the importer is
**not a proof of agreement between Lean and HOL**. Review the constructor
mapping and pin when changing the guest. The Pancake parser is not used to
redefine the challenge's authoritative input.

## Target restriction

`source/instruction-subset.json` records the pinned Flapjack L3 instruction
carrier. This subset is narrower than ordinary RV64IM: for example, it includes
`ADDIW` but excludes `ADDW`, `MULW`, and word shifts. FP, atomics, privileged
operations other than the retained system calls, and compressed instructions
are excluded. `challenge/initTargetScript.sml` applies the whitelist to the
upstream decoder and derives a new `Next` body using the restricted decoders.

The target restriction applies to every participant, regardless of compiler.
An instruction check on baseline compiler output is not a replacement for it.
The current restricted step reuses upstream L3 semantics. Agreement with the
pinned reduced Lean decoder and step remains to be proved; the challenge's
initial state and oracle hooks are fixed in `initMachine` and `initSubmission`.
The compiler correctness theorem still needs a bridge to this evaluator.

## Reproduce the compiler and verifier

```sh
python3 tools/build.py --hol /path/to/HOL initArtifactsTheory.uo
python3 tools/prepare_verifier.py --hol /path/to/HOL
python3 verifier/verify.py --local /path/to/submission --hol /path/to/HOL
```

[Checked native artifacts](artifacts/README.md) are included in `artifacts/`.
The compiler target writes `compiled.bin`, `bitmaps.txt`, and `backend.conf`
under ignored `.build/`. These are native compiler artifacts, not an admitted
challenge ROM. Large evaluated theories require substantial memory and time
to export. Use the tested HOL pin in `provenance.json` for verifier preparation.

The fixed challenge and accelerator regression theories build successfully.
Six AST importer tests and twenty-five verifier tests pass. Strict replay component
tests cover valid proofs and forged axioms; the real verifier rejects a valid
article whose conclusion is merely `T`. No positive full-certificate replay is
claimed yet.

See [experiment results](experiments/RESULTS.md) for the compiler results and
[the verifier boundary](verifier/README.md) for statement binding.

## Remaining certificate obligations

1. Prove agreement with the pinned reduced Lean decoder and machine step.
2. Connect compiler correctness to the restricted target and cache-hook
   evaluator, discharging configuration, memory, resource, and non-failure
   premises.
3. Prove the complete baseline `Certificate` and export a replayable article.

The full compiler installation predicate (`pan_installed`) is proved for states
related to the checked bootstrap final state, including native bytes, bitmap
allocation, startup headers, and MMIO layout.

`cv_compute` replaces concrete evaluation proofs; these semantic obligations
still require proofs. No admitted theorem fills the gaps. The 56,017-file Lean
submission proof tree is neither copied nor built.
