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

## Certificate continuation

The baseline zero-RAM bootstrap in `initBootstrapScript.sml` passes an isolated
HOL build, including its 208-byte size, instruction and layout checks. The
native entry is 0x80000400, leaving space for the bootstrap/dispatch slots while
keeping the larger native output below the fixed source code-buffer headers.
Encoding and layout facts do not by themselves prove bootstrap execution.
`initBaselineRom` also passed an isolated build: its 950,336-byte image contains
the exact native bytes and initialization data at the specified offsets. The
candidate image is in `artifacts/baseline/`, with no admission or Certificate
proof claimed.

The build driver now includes upstream Pancake/backend/RISC-V semantic proof
sources. `pan_to_targetProofTheory` and `riscv_targetProofTheory` are required
prerequisites for the semantic certificate. The old-toolchain build exposed
failures in `bvl_to_bviProof`, `clos_callProof`, and `word_instProof`; other dependencies continue
building. A compatibility test with the newer provenance HOL pin failed earlier
in `flatLang` (`exp6_size` missing), so that pin has not replaced `tested_hol`.
The missing register-allocation proof directory has also been added to the
build search path for the next semantic build.

The single Python entry point now supports `--local`, `--structural-only`,
`--progress`, and `--hol`, with automatic preparation of the fixed verifier.
Twenty Python boundary/command tests pass. The complete certificate and the
remaining original CLI options are still outstanding.

The newer HOL failure coincides with its October 3 datatype-package switch;
the August checkout predates the September tactic updates. An isolated checkout
at `7f769972f0acf26df39facd83339c05a66d9ff26` (October 1) is being built to test
the combination of newer tactics and the previous datatype package. It is an
unverified compatibility candidate, not a replacement for `tested_hol` yet.

## Bootstrap execution lemmas and toolchain compatibility

`initBootstrapMemoryTheory` passes the normal HOL build. It proves byte reads
and writes, exact eight-byte copying, preservation of other memory and
registers, non-failure under alignment/domain premises, and commutation with
PC updates. The word-result width is explicitly 64 bits, independently of the
address width in HOL's polymorphic `read_mem_word`.

`initBootstrapLoopTheory` also passes (40 s observed). It takes its five
instructions directly from `bootstrapBlocks`, computes their encoder lengths
with cv, and proves the complete assembler-state effect: copied memory, both
pointers advanced by eight, preserved end pointer/domain/endian/failure flag,
and the exact back-edge or fall-through PC. This still requires instruction
installation and RISC-V simulation to obtain the full machine trace.

The October 1 HOL compatibility candidate built successfully. All four
previously failing theories (`bvl_to_bviProof`, `clos_callProof`, `word_instProof`,
and `panProps`) now pass unchanged. A full compiler/challenge/semantic-proof
build is running in `.build-hol-compatible`; `tested_hol` remains unchanged
until that wider validation succeeds. Missing GC and register-allocation proof
source directories are now included by the build driver.

The real `verify.py --local` path automatically rebuilt its stale fixed heap
and rejected the unrelated truth article after preparation. Twenty Python
verifier tests also pass. No positive baseline Certificate is claimed.

## Finite bootstrap initialization copy

`initBootstrapIterationTheory` passes the normal build (31 s observed). It
proves pointer advancement, preservation of memory outside the destination,
byte-for-byte copying under explicit separation premises, non-failure under
alignment/domain premises, and the exact loop branch/exit PC for any finite
iteration count. Its loop body is the five actual bootstrap instructions.

`initBootstrapCopyTheory` specialises these facts to the fixed layout. The
4,616 iterations copy all 36,928 initialization bytes from ROM to RAM, preserve
all other memory, and exit after the final word. The concrete source/destination
separation and alignment arithmetic is proved, with memory-domain membership
remaining an explicit premise. The full theory rebuild passed (33 s observed).

`initBootstrapStartupTheory` passes the normal rebuild (35 s observed). It
proves the three actual prefix instructions set
the expected pointers and enter the copy loop at `0x80000018`. Its composed
`bootstrap_copy_effect` theorem reaches `0x8000002c`, copies the full data
range, preserves other memory, and has no failed-state flag, assuming the
initial PC, little-endian/non-failed state, and access to both memory ranges.

These are proofs of the assembler state updates. Instruction installation,
RISC-V step simulation, the remaining bootstrap stores, and composition with
compiler correctness remain necessary for the complete Certificate. No
participant statement or fixed verifier condition was relaxed.

The compatibility build also passed upstream `riscv_targetProofTheory`
(349 s observed). `pan_to_targetProofTheory` and the final evaluated artifact
theories are still running; the recorded tested toolchain has not changed.

## Complete bootstrap assembler-state effect

The full compatibility build at HOL
`7f769972f0acf26df39facd83339c05a66d9ff26` passed all 230 requested theories,
including `pan_to_targetProofTheory` (490 s), `riscv_targetProofTheory`
(349 s), the fixed challenge and replay theories, full compiler computation,
and `initBaselineRomTheory`. The resulting native bytes, bootstrap bytes,
and baseline ROM match the checked-in artifact hashes exactly. The copy,
iteration, and startup theories also passed on this HOL version.

`initBootstrapStoresTheory` proves a factored little-endian byte-memory view
of `write_mem_word` and `mem_store`, including selected-byte and outside-memory
lemmas. `initBootstrapSuffixTheory` proves the actual suffix's entry registers,
entry PC, eight exact header/pointer stores, and non-failure under the two
explicit writable-range premises. Reducing individual instruction projections
avoids the large expression expansion caused by unfolding the entire state.

`initBootstrapState.bootstrap_final_effect` composes the entire bootstrap's
assembler state updates through native entry. It passed the normal build
(27 s; its suffix ancestor took 66 s). The theorem states the native PC,
registers 10--13, non-failure, and the exact installed byte-memory function.
The input PC, little-endian/non-failed input state, and ROM/RAM domain premises
remain explicit. Instruction installation and RISC-V execution simulation are
not supplied by this state-update theorem. The complete challenge Certificate
and positive certificate replay remain unfinished.

The recorded `tested_hol` pin is now the October 1 revision above. The original
August build cache was preserved locally, and `.build` selects the existing
compatible cache without relocating its generated loaders. Twenty verifier
unit tests and six importer tests pass with the updated trusted pin/manifest.

The final suffix and composed-state theories also passed on the new tested
HOL pin (69 s and 32 s). The fixed verifier heap was rebuilt successfully.

The real-HOL replay regression on this heap loaded all 904,476 submitted
literal bytes and rejected an unrelated truth theorem at the exact Certificate
conclusion check. This is a negative boundary test, not a positive certificate.

## Original verifier CLI options

The single Python entry point now supports all original option names:
`--local`, `--trusted`, `--work`, repeatable `--hide`, `--structural-only`, and
`--progress`. The trusted root is explicit operator input. Work directories
are fresh/private and retain the sanitized submission and replay log. Path
hiding uses Bubblewrap with read-only host mounts and a writable private
workspace; inability to apply isolation rejects the replay.

All 25 verifier unit tests pass, including trusted-root selection, retained
literal snapshots, immutable input across preparation retries, and rejection
of missing sandbox support or hidden required paths. A real isolation test
checks both file and directory masking, unchanged host files, and workspace
writes. A real subprocess test invokes the original CLI flags with all
904,476 bytecode bytes, hides the original submission and a separate private
directory, automatically rebuilds the stale heap, and reaches the exact
Certificate-conclusion rejection for an unrelated proof. The full baseline
Certificate and positive replay are still outstanding.

## Native-byte installation and compiler layout bridge

`initBootstrapFrameTheory` passed (31 s). It proves preservation of memory
below initialization RAM, the memory domain/endian flag, and CakeML's
`bytes_in_memory` predicate for code in that range.

`initInitialCodeTheory` proves byte installation from the fixed
`initialMemory` definition. Code-range bytes are independent of shared
input/output memory. Addresses at or above the submission anchor cannot
coincide with reserved FFI entries under the challenge's anchor-spacing
condition. Its general code-slice installation theorem passed (14 s).

`initNativeInstalledTheory` passed (76 s). It connects the checked ROM-slice
equality to the exact compiled native bytes in initial memory, then preserves
their installation through the bootstrap state updates. Its premises bind
the submission to `baselineRom` and `baselineNativePc`, retain the FFI spacing
condition, and bind the assembler memory/domain to the fixed initial memory
and program domain. This does not prove a RISC-V execution trace.

`pancakeCorrectnessBridgeTheory` passed (18 s). With performance calls disabled,
the compiler entry point used by Pancake's semantic correctness theorem and
the concrete `from_word_0` pipeline produce equal bytes, bitmaps, and target
layout. Symbol names and intermediate configuration bookkeeping are projected
out by a proved equality. The stack/resource and source-semantic premises of
the correctness theorem remain necessary.

`initCorrectnessInput.guest_correctness_compilation` instantiates that bridge
for the fixed prepared guest and checked allocation. The theorem gives a
successful `compile_prog_max` result containing the exact `compiledBytes`,
`compiledBitmaps`, and target layout from `compiledConfig`. The stack maximum
is an existential output, not an established resource bound. This discharges
the concrete compilation premise, not all premises of semantic correctness.
The complete `initCorrectnessInputTheory` rebuild passed on the tested HOL pin
in 81 s. All new results are checked for hypotheses and untrusted theorem tags.

## Source correctness premises

`initSourceChecksTheory` passed a fresh build (65 s). Kernel-checked evaluation
of the fixed `prepared_guest` proves `pancake_good_code`, distinct parameters,
distinct function names, and the exception-count bound required by
`pan_to_target_compile_semantics`. The operand traversal uses first-order
recursive equations proved equivalent to the upstream `every_exp` predicate;
its translation preconditions are discharged by datatype induction.

`initGlobalLayoutTheory` passed (61 s). The guest has no named-structure
declarations, its structure context is empty, and its global declarations
occupy exactly **93 words**, equal to the fixed challenge's `globalsWords`.
Declaration checks and shape extraction use `cv_compute`; the small resulting
shape list is evaluated in the kernel.

`initSourceAllocationTheory` passed its final rebuild (56 s). It proves the
global allocation premise for every input
of the fixed `sourceInitialState`. Ordinary memory lies below the globals,
the globals lie above ordinary memory, the region endpoint is outside ordinary
memory, and its byte size fits in 64 bits. `prepared_source_premises` combines
this result with the syntax checks and empty initial code/local/global/exception
maps. These are closed results checked for hypotheses and untrusted theorem tags.

Reproduce this theory chain with:

```sh
python3 tools/build.py --hol /path/to/tested-HOL initSourceAllocationTheory.uo
```

The results discharge specific source-side premises of the compiler theorem.
They do not establish equivalence between the original and reordered declaration
semantics, target installation/execution, sufficient runtime stack/heap bounds,
or the final challenge Certificate. A positive full certificate replay remains
outstanding.
