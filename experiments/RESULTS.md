# cv_compute results, 2026-10-07

Dependency pins are in `../provenance.json`; builds use `tested_hol`.
The source submission has 56,017 Lean files. None of its generated proof tree
was copied or built. The pinned literal AST contains 928 declarations.

## Full compiler computation

The complete guest passed simplification, struct lowering, global lowering,
Crep, loop, word, register allocation checking, and RISC-V backend encoding.
The native allocator is an untrusted hint generator; the logical backend checks
the hint before returning bytes. All saved computation results are checked for
hypotheses and untrusted theorem tags.

Native output:

- Length: **904,476 bytes**.
- SHA-256: `4403ff7d9c7b663ba20a4e9c961547b2548530a56b15f238248886763009489e`.
- This is compiler code, **not a bootstrapped challenge ROM**.

`initCompilationInput.top_compile_to_backend` proves the composition from the
ordinary top-level Pancake compiler to its backend input. `initBytecode` evaluates
the backend, proves successful completion and the byte count, and exports the
byte array. `pancakeBackendBridge` proves correspondence between the cv backend
wrapper and the ordinary backend. `initCompileProof` composes these results;
`initArtifacts` exports 4,613 bitmap words and encoded configuration data.
It also proves the exact result triple using the proved configuration
encode/decode round trip. The checked
source-to-bytecode theorem is:

```text
|- ?bm c. pan_to_target$compile_prog riscv_config
            (set_oracle pancakeRiscvConfig allocation) guestAst =
          SOME (compiledBytes,bm,c)
```

`initBytecode` and `initCompileProof` passed in 182 s and 73 s of Holmake wall
time respectively on the final run, including ancestor loading.

```sh
python3 tools/build.py --hol /path/to/HOL initArtifactsTheory.uo
```

Generated files are `.build/compiled.bin`, `.build/bitmaps.txt` (decimal word64
values, one per line), and `.build/backend.conf` (CakeML's configuration encoding).
The kernel-checked byte result is separate from the file writer and external
SHA-256 reporting; no cryptographic digest equality is claimed as a HOL theorem.

### Translation details

All passes share CakeML's `backend_64_cv` codecs, including wordLang and mlstring.
Record literals are converted to constructors using proved reconstruction
identities and fully evaluated before deep embedding. Specializations of
higher-order helpers, mutual recursion, sorting, and finite-map representations
are proved from their original definitions.

The RISC-V specialization retains raw defining equivalences as well as evaluation
equations, allowing the evaluated wrapper result to be related to the original
backend. Native allocation is never accepted as a proof. No upstream CakeML
source was edited; derived translation/correspondence files carry its BSD notice.

Large literal theories disable HTML theorem pretty-printing: that optional
output grew to 24 GB for the bytecode result alone. Serialized HOL theory data
is far smaller. Compilation and loading still need substantial RAM.

Selected observed Holmake wall times (cached prerequisites; not benchmarks):

| Theory | Time |
| --- | ---: |
| initSimplify | 140 s |
| initGlobals | 84 s |
| initCrep | 95 s |
| initPrepared | 235 s |
| initLoops | 199 s |
| initWord | 154 s |
| initCompilationInput | 62 s |
| backendRiscvCv | 57 s |
| pancakeBackendBridge | 15 s |

The reproducible native artifacts are checked in under `artifacts/`.

## Fixed challenge and verifier

The challenge now fixes the source initial state, accelerator oracle, reduced
instruction decoder, machine initial state, dispatch hooks, cache-hook evaluator,
admission rules, observations, and certificate proposition. Metadata is an
admitted existential witness bound to the submitted code. The score is finite
or Infinity; both require termination on every covered source execution.

Keccak and SHA-256 known-answer checks pass, along with modular arithmetic,
curve/Fp2, malformed input, and accelerator rejection regressions. Initial PC,
zero registers/RAM, initial target validity, byte limits, cache return, and
infinite-score termination lemmas build successfully. These tests do not prove
Lean/HOL semantic agreement.

Six AST importer tests and sixteen Python verifier boundary tests pass. The
pinned AST reimports exactly. The strict OpenTheory replay component tests valid
proofs, forged axioms, altered conclusions, assumptions, invalid theorem tags,
and fixed-constant replacement. The prepared verifier rejects a valid article
proving `T` instead of the fixed Certificate, after loading all 904,476 bytes as
literals. This runtime regression is reproducible with `verifier/test_replay.py`.

Replay uses frozen bytes and sanitized score literals, a fixed operator heap,
a private working directory and resource limits. It checks the exact closed
certificate statement. There is no participant ML execution or admitting-axiom
fallback. No positive full Certificate replay has been produced yet.

## Remaining proof work

The baseline challenge certificate is **not proved**. Outstanding work includes
reduced-target semantic agreement, connecting compiler correctness to the fixed
cache-hook evaluator, wellformedness and configuration/resource premises,
bootstrap and installation from zero RAM, and a complete replayable article.
The upstream compiler correctness theorem has explicit installation and resource
premises; the concrete compiler equality does not discharge them.
