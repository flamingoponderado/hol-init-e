# hol-init-e

An experimental port of the [init-e challenge](https://github.com/flamingoponderado/init-e).
Participants submit arbitrary RISC-V bytes; the fixed guest, supported target
instructions, observations, and execution budget define the challenge.
CakeML's Pancake compiler supplies one route to a baseline submission.

The experiment replaces generated Lean computation certificates with HOL4
`cv_compute` evaluations. The generated Lean proof tree is not imported.
This repository does **not yet contain a complete challenge certificate or
a proved source-to-bytecode compilation**.

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
candidate files. It never executes candidate ML. It is deliberately fail closed:
preflight success returns **incomplete (exit 2)**, not verified. Full independent
proof replay and the fixed Certificate still need implementation. See
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
- A full-guest `pan_simp` pass experiment producing a kernel-checked equality
  by `cv_eval_pat`, with the result retained as a named constant.

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
initial state, oracle hooks, and evaluator must also be connected to this step.

## Checked so far

The complete 928-declaration guest is accepted by HOL4. The budget/layout proofs,
restricted-target lemmas and raw instruction decoding tests pass. The full-guest
simplifier experiment proves:

```text
|- LENGTH guestAst = 928
|- pan_simp$compile_prog guestAst = simplified_guest
```

The experiment checks that these results have no assumptions or admitted-proof
tags. It normalizes record literals and boolean encodings before registering
the guest with `cv_compute`. It does not import generated Lean proof modules.
The tested HOL revision is recorded separately as `tested_hol` in provenance.

See [experiment results and the reproduced next-stage blocker](experiments/RESULTS.md).

## What remains

1. Translate the remaining Pancake passes and the RISC-V backend to cv
   equations. CakeML has backend specialization for RISC-V, but its ready-made
   cv compiler drivers target x64, ARM8, and AG32. Measure full-guest
   compilation and prove an equality to a separately recorded byte artifact.
2. Instantiate compiler correctness for the restricted target. Reusing
   `pan_to_target_compile_semantics` requires its configuration, installation,
   memory, resource, and non-failure premises, plus a restricted-step bridge.
3. Port the fixed initial state, source semantics, shared-memory and accelerator
   FFI, declared-gas decoder, observations, and submission admission rules.
4. Prove bootstrap/installation and the complete challenge certificate. The
   compiler equality alone does not prove termination or a finite score.

`cv_compute` can replace concrete evaluation proofs; it cannot replace these
semantic obligations. No admitted theorem is used to fill the gaps.
