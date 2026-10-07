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
candidate image is in `artifacts/baseline/`. Its admission proof is now checked
(see below); its full Certificate remains unproved.

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
Target installation/execution, sufficient runtime stack/heap bounds,
and the final challenge Certificate remain separate obligations. A positive full certificate replay remains
outstanding.


## Compiler source order preserves challenge behavior

`panMainOrderTheory` passed (7 s). A function declaration commutes with a
neighboring declaration when the neighbor does not define the same function
name. This covers globals and exceptions as well as functions; global
initializer evaluation is independent of the function map. Induction lifts the
swap to a declaration prefix. Named-structure processing is also preserved.

`initSourceOrderTheory` passed (59 s). Checked evaluation shows the fixed AST
ends with `main` and the prefix contains no other function of that name.
Instantiating the generic theorem proves, for any initial state and start name,
that `prepared_guest` and `guestAst` have equal declaration semantics. In
particular:

```text
|- semantics_decls (sourceInitialState input) «main» prepared_guest =
   sourceBehaviour input
```

This closes the source-order gap between the compiler correctness theorem and
the fixed challenge. All exported semantic results are checked for hypotheses
and untrusted theorem tags. The challenge definitions are unchanged.

```sh
python3 tools/build.py --hol /path/to/tested-HOL initSourceOrderTheory.uo
```

## Exact serialized compiler configuration

`initConfigNumbersTheory` checks a proposed list of 69,393 numbers against
the saved configuration characters and derives exact character decoding using
the upstream inverse theorem. `initDecodedConfigTheory` then obtains a candidate
record from a conditional decoder translation and checks its entire encoding:

```text
|- encode_backend_config candidateConfig = compiledBackendConfig
|- compiledConfig = candidateConfig
```

The final configuration theorems are closed and checked for untrusted theorem
tags. Decoder preconditions are retained, and their conditional results supply
only candidate data. The unconditional encoding equality and upstream
encode/decode inverse establish the result. The local decoder translator derives
a variant of the pinned HOL translator without modifying HOL or CakeML sources;
it fails if the expected source patterns change.

The split configuration theory passed (253 s wall time, including ancestor
loading). This result supplies exact compiler metadata; it does not establish
baseline admission or the challenge Certificate.

```sh
python3 tools/build.py --hol /path/to/tested-HOL initDecodedConfigTheory.uo
```

## Baseline submission admission

`initCompiledMetadataTheory` passed (79 s wall time). Its checked configuration
contains **20 external FFI names** and **13 MMIO records**, for 33 total names.
Every MMIO address offset is nonnegative.

`initBaselineAdmissionTheory` passed its complete build. It proves:

```text
|- baselineMetadataRoundtrip
|- admitted baselineSubmission
|- initialPc + LENGTH bootstrapBytes <
   baselineNativePc - ffiOffset * (compiledFirst + 2)
```

The submission uses the exact 950,336-byte baseline ROM and the exact compiled
metadata. The roundtrip check rules out information loss when converting signed
compiler offsets to the natural offsets of the fixed challenge. Admission is
proved by kernel evaluation of the concrete metadata and proved ROM length,
using finite-quantifier equivalences. Compiler computation and metadata literal
extraction use `cv_compute`. All exported results are closed and tag-checked.

```sh
python3 tools/build.py --hol /path/to/tested-HOL initBaselineAdmissionTheory.uo
```

This establishes layout admissibility. Actual bootstrap execution, compiler
resource/installation premises, restricted-machine simulation, and the complete
challenge Certificate still require proofs. No positive full certificate replay
is claimed.

## Bootstrap instruction fetch

`initBootstrapInstalledTheory` passed. It proves that the bootstrap's 208 bytes
are installed in the admitted baseline's initial program domain, for every
input. A domain lemma excludes all reserved dispatch slots below native entry.
Checked evaluation verifies the offset, bounds, and exact encoded slice for
every bootstrap instruction. A generic memory-slice theorem then yields:

```text
|- MEM (pc,instruction) bootstrapBlocks ==>
   bytes_in_memory (n2w pc) (riscv_enc instruction)
     (initialMemory baselineSubmission input)
     (programDomain baselineSubmission)
```

All exported results are closed and checked for untrusted tags. This establishes
initial fetchability. The bootstrap execution trace must still establish these
fetch premises and successful assembler steps at each intermediate state,
including every copy-loop iteration, before lifting to restricted RISC-V.

```sh
python3 tools/build.py --hol /path/to/tested-HOL initBootstrapInstalledTheory.uo
```

## Bootstrap assembler steps and startup execution

`initBootstrapStepTheory` passed. Its ROM invariant fixes the program domain
and preserves initial memory below `bootDataRam`. The fetch-preservation theorem
transfers the checked instruction encodings to any state satisfying that
invariant. `bootstrap_asm_step` then establishes the upstream `asm_step` relation
for a bootstrap instruction, given its declared PC, RISC-V configuration fields,
and a non-failing `bootAfter` result.

`initBootstrapPrefixStepsTheory` also passed. It defines `bootSteps` as a finite
sequence of those actual assembler steps and proves it for the three startup
instructions from the initial PC. The premise requires the ROM invariant,
link register index 1, little endian state, alignment 2, and no initial failure.
The instruction memberships and encoded lengths are checked in HOL. All
exported results are closed and tag-checked.

```sh
python3 tools/build.py --hol /path/to/tested-HOL initBootstrapPrefixStepsTheory.uo
```

The copy-loop iterations and suffix still need their step-sequence proofs.
The restricted RISC-V simulation and full challenge Certificate remain
outstanding; these startup results do not imply a complete certificate.

## Trace composition and copy-loop ROM preservation

`initBootstrapExecutionTheory` passed. `bootSteps_append` composes checked
instruction sequences, and `bootSteps_RTC` turns such a sequence into the
upstream reflexive-transitive assembler-step relation ending at `bootRun`.
Configuration fields (link register index, alignment, endianness, and memory
domain) are preserved by `bootRun`; the link register index and alignment are
also preserved by `copyIterations`.

The ROM invariant is preserved by one copy-loop state update and by any finite
number of iterations when their destination bytes lie at or above
`bootDataRam`. These results use the existing proved write-footprint lemmas;
all exported results are closed and tag-checked.

```sh
python3 tools/build.py --hol /path/to/tested-HOL initBootstrapExecutionTheory.uo
```

The step premises for the five instructions in a copy-loop iteration must
still be established and composed through all 4,616 iterations. ROM
preservation alone does not prove those steps or the final Certificate.

## Copy-loop instruction execution

`initBootstrapCopyStepsTheory` passed. `copy_loop_steps` proves `bootSteps
copyLoopBody s`: the load, store, two pointer increments, and conditional branch
all take valid upstream assembler steps. Its premises require the fixed loop
entry PC, the RISC-V configuration fields, no initial failure, aligned source
and destination words, membership of all eight accessed bytes in the memory
domain, and destination bytes above the executable ROM.

The theory checks load safety, load/store configuration-field preservation,
and preservation of the ROM invariant. It handles both branch outcomes. The
encoded instruction lengths and membership at their fixed bootstrap PCs are
checked in HOL. All exported results are closed and tag-checked.

```sh
python3 tools/build.py --hol /path/to/tested-HOL initBootstrapCopyStepsTheory.uo
```

The finite 4,616-iteration execution theorem remains to be assembled from this
per-iteration result and the existing pointer, memory, and branch-bound proofs.
Suffix execution, restricted RISC-V simulation, and full Certificate replay
also remain outstanding.

## All 4,616 copy iterations execute

`initBootstrapCopyExecutionTheory` passed. It composes the checked five-instruction
loop body into `copyInstructions 4616` and proves that its state update agrees
with `copyIterations 4616`. The fixed address bounds establish alignment,
memory-domain membership, and ROM separation at every intermediate iteration.
The proof also establishes each iteration's loop-entry PC and non-failure.

`baseline_copy_execution` proves the upstream reflexive-transitive assembler-step
relation from loop entry to `copyIterations 4616 s`, given the initial ROM
invariant, configuration fields, fixed source/destination/end pointers, no
initial failure, and membership of the 36,928 source and destination bytes in
the memory domain. All exported results are closed and tag-checked.

```sh
python3 tools/build.py --hol /path/to/tested-HOL initBootstrapCopyExecutionTheory.uo
```

This closes finite copy-loop execution at the assembler level under those
premises. Connecting the complete startup/copy/suffix trace from the fixed
initial machine state, lifting it to restricted RISC-V, and completing the
challenge Certificate remain outstanding.

## Runtime-initialization suffix execution

`initBootstrapSuffixStepsTheory` passed its complete build (8m24s for the theory,
plus ancestor loading). It proves `bootSteps bootstrapSuffix s`, covering the
runtime-bound stores, source-header stores, native-entry register setup, and
final jump. The premises are the ROM invariant, suffix-entry PC, RISC-V
configuration fields, no initial failure, and membership of the 24-byte and
40-byte initialization regions in the memory domain.

Each instruction uses the checked fetch/step theorem. Generic store-field
preservation and the low-memory write-footprint rule discharge configuration
and ROM-preservation conditions. All exported results and generated rewrite
rules are closed and tag-checked. Evaluation never unfolds the entire baseline
ROM to prove a store's local memory-domain premise.

```sh
python3 tools/build.py --hol /path/to/tested-HOL initBootstrapSuffixStepsTheory.uo
```

Composition with startup and copy execution, connection to the fixed initial
machine, restricted RISC-V simulation, and the final Certificate remain separate
obligations.

## Complete assembler bootstrap trace

`initBootstrapFullExecutionTheory` passed. `bootstrap_full_execution` composes
the startup prefix, all 4,616 copy iterations, and the initialization suffix into
the upstream reflexive-transitive assembler-step relation from `s` to
`bootFinalState s`. ROM preservation is carried across both phase boundaries.

The theorem assumes the initial PC and RISC-V configuration fields, the initial
ROM invariant, no initial failure, and membership of the copy-data and header
regions in the memory domain. The existing `bootstrap_final_effect` supplies
the native-entry PC, registers, and final memory effects. All exported results
are closed and tag-checked.

```sh
python3 tools/build.py --hol /path/to/tested-HOL initBootstrapFullExecutionTheory.uo
```

This closes composition of the assembler bootstrap trace. The fixed initial
challenge machine must still be related to an assembler state satisfying these
premises. Restricted RISC-V simulation, compiler resource/installation premises,
and the complete challenge Certificate and positive replay remain outstanding.


## Fixed initial assembler state and native entry

`initBaselineInitialTheory` passed a clean build (91 s reported theory time,
plus ancestor loading). `baselineInitialAsm input` explicitly fixes every
assembler-state field: zero registers, the challenge's `initialMemory` and
`programDomain`, initial PC, and RISC-V configuration fields.

- `baseline_bootstrap_domains` discharges all 36,928 source and destination
  copy-byte memberships and all 40 source-header byte memberships.
- `baseline_initial_target_relation` relates this assembler state to the fixed
  challenge `initialState baselineSubmission input` using upstream
  `target_state_rel`.
- `baseline_bootstrap_execution` proves the complete assembler-step RTC from
  that concrete initial state to `bootFinalState`, with no remaining premises.
- `baseline_native_installed` proves that the exact compiled native bytes are
  installed in the resulting memory and domain.
- `baseline_native_entry` proves the native entry PC, registers 10–13, and the
  absence of assembler failure.

All results are kernel checked, closed, and tag checked. The input remains
universally quantified. This discharges the concrete initial-state premises
of the preceding bootstrap trace; lifting the trace to restricted RISC-V and
`challengeEvaluate`, compiler semantic installation/resource premises, and a
complete Certificate with positive replay remain outstanding.


## Restricted instruction step agreement and bootstrap words

`initRestrictedStepTheory` passed (13 s reported theory time). It proves that
`restrictedNextRISCV` and upstream `NextRISCV` agree whenever the fetched
instruction is a full word whose decoded constructor is supported. The
corresponding target-next equality and equality of target-state relations are
also checked. Fetch and support are explicit premises; this is not yet an
execution trace transfer.

`initBootstrapRestrictedTheory` passed (33 s reported theory time). Checked
computation constructs the 52 little-endian words from the exact 208 bootstrap
bytes and proves that every word decodes to a supported instruction. The
indexed corollary `bootstrap_word_supported` applies at each offset `4*i` for
`i < 52`. Both theories check that their exported results are closed and have
acceptable proof tags. Native-code support and the whole restricted execution
trace remain outstanding.


## Encoder correctness for the restricted RISC-V target

`initRestrictedRulesTheory`, `initRestrictedEvaluatorTheory`,
`initRestrictedTargetTheory`, and `initRestrictedEncoderTheory` passed.
The encoder proof took 5m07s of theory time, plus loading. Its final result is:

```text
|- encoder_correct restrictedTarget
```

The adapted proof retains the pinned CakeML assembler/configuration arguments.
A local evaluator is derived from the pinned HOL RISC-V step library. Before
applying each restricted step rule, it proves that the decoded instruction's
constructor satisfies `supported_instruction`. It never asserts this premise
or widens the challenge's decoder. The adapter refuses unsupported `ADDW`;
checked arithmetic, load, store, conditional-branch, and jump examples pass.
The HOL and CakeML checkouts are not modified by this adapter.

The full encoder proof covers all valid assembler instructions under the
RISC-V configuration, including the absence of usable floating-point registers.
The final theorem is closed and passes `check_thm`. This supplies the restricted
encoder premise required by compiler correctness, rather than an unchecked
whole-ROM instruction scan.

`initEncoderExecutionTheory` also passed. `encoder_rtc_reaches` lifts a finite
assembler-step RTC and an initial target-state relation to finite target-next
execution with the final target-state relation. This generic result does not
by itself establish the additional checks of `challengeEvaluate`.


## Restricted CPU bootstrap execution from the fixed initial state

`initBaselineRestrictedExecutionTheory` passed a clean build (96 s reported
including theory loading). For every input, `baseline_restricted_execution`
proves a finite RTC of `restrictedTarget.next` from
`initialState baselineSubmission input` to a state related to the complete
assembler bootstrap result.

`baseline_restricted_native_entry` exposes the resulting machine facts:

- `riscv_ok final`;
- native entry PC `0x80000400`;
- registers 10–13 equal the native entry, source base, stack start, and RAM end;
- all exact compiled native bytes installed in `final.MEM8` under the fixed
  `programDomain baselineSubmission`.

Both execution results are closed and tag checked. This is execution of the
restricted CPU from the challenge's actual initial state, including zero RAM.
It does not yet prove execution by `challengeEvaluate`, whose program-domain,
FFI, and memory-interference checks must also be connected. The full baseline
Certificate and positive article replay are still not proved.


## Restricted machine-configuration premise

`initMachineConfigTheory` passed a clean build (15 s reported). It derives
`enc_ok riscv_config` from restricted encoder correctness and proves:

```text
|- mc_conf_ok (challengeMachineConfig pc program shared names nexternal extra)
```

This holds for arbitrary layout arguments; admission separately validates the
concrete layout. It discharges the compiler theorem's `mc_conf_ok` premise for
the challenge machine. Backend configuration, initial installation, resource
bounds, and semantic/evaluator composition remain distinct obligations.


## Normal-instruction simulation inside the fixed challenge evaluator

`initChallengeStepTheory` passed a clean build (16 s reported). It adapts the
pinned CakeML `targetProps` normal-instruction prefix proof to
`challengeEvaluate`. The theorem `asm_step_IMP_challenge_step` proves that an
assembler step executes in a nonzero number of challenge-evaluator steps,
with the final target-state relation and equality for every remaining fuel.
Its premises retain encoder correctness, matching program/memory domains,
instruction-range disjointness from FFI entries, permitted interference, and
the initial target-state relation.

Only the normal-instruction evaluator branch is used. The fixed cache-hook
and FFI branches retain their challenge definitions. Explicit 64-bit RISC-V
configuration types are required in inherited tactic instantiations to avoid
introducing unrelated polymorphic configurations with the same printed name.
Both exported simulation theorems are closed and tag checked. Trace composition
and concrete bootstrap FFI-disjointness remain to be instantiated.


## Composition of challenge-evaluator instruction prefixes

`initChallengeExecutionTheory` passed a clean build (15 s reported).
`challenge_rtc_execution` composes a finite `challengeAsmEdge` trace into an
equality of `challengeEvaluate` prefixes for every remaining fuel, preserving
the final target-state relation. Each edge explicitly requires an assembler
step, the fixed program/memory domain, and an instruction range disjoint from
FFI entries. `challenge_identity_interference` discharges the identity
interference premise for `challengeMachineConfig`; `identity_shift_interfer`
shows that consuming such interference leaves the configuration unchanged.

The composition and instruction results are closed and tag checked. Applying
the theorem to the concrete bootstrap requires the stronger assembler trace
with the FFI-range condition on every edge; the previously proved raw CPU RTC
alone does not supply that condition.


## Correct native placement for the fixed source header

The installation predicate `pan_installed` requires the source header's code
buffer start to equal native entry plus the exact compiled byte count. The
fixed challenge source memory contains `0x800ddd08` in that header. The former
entry `0x80000400` ended the 904,476-byte image at `0x800dd11c`; the earlier
non-overlap inequality was insufficient for installation.

The candidate native entry is now **`0x80000fec`**, making its end exactly
`0x800ddd08`. The fixed challenge/source definitions and compiled native bytes
are unchanged. `initBootstrap`, `initBaselineRom`, and `initBaselineAdmission`
passed clean rebuilds (31 s, 85 s, and 108 s reported). The new closed,
tag-checked theorem `native_ends_at_fixed_buffer` proves the required equality.
The candidate ROM and bootstrap binaries and their manifest hashes were
regenerated from these checked builds. Dependent execution proofs are being
rebuilt for this placement; earlier sections reporting `0x80000400` describe
the previous development layout. The full Certificate remains unproved.


## Bootstrap FFI separation and strengthened instruction steps

For the corrected native placement, `initBootstrapFfiTheory` and
`initBootstrapChallengeStepTheory` passed clean builds (92 s each reported).
Checked computation derives all baseline FFI addresses and proves that they
are at or above the end of the 208-byte bootstrap. The range theorem and
`bootstrap_instruction_ffi_disjoint` then show that every bootstrap instruction
is disjoint from those entries.

`bootstrap_challenge_step` combines that result with the actual assembler-step
proof and the fixed ROM/domain invariant. `challengeBootSteps` records the
stronger edges required by the challenge-evaluator simulation;
`challengeBootSteps_append` and `challengeBootSteps_RTC` compose them.
All exported results are closed and tag checked. The strengthened whole-trace
build is continuing through startup, the copy loop, and initialization.


## Complete bootstrap execution in the fixed challenge evaluator

The dependent proofs were rebuilt for native entry `0x80000fec`. Both suffix
proofs passed (615 s for the assembler trace and 623 s for the stronger
challenge trace, including ancestor loading). The prefix, 4,616-iteration copy
loop, final stores, native entry, and ROM preservation compose into
`bootstrap_challenge_trace`.

`initBaselineChallengeExecutionTheory` then passed a clean build (93 s).
`baseline_challenge_execution` proves the existence of a finite prefix length
and native-entry machine state such that, for every remaining fuel, evaluating
the fixed baseline from its fixed initial state is exactly evaluating from that
native-entry state. The final state is related to the proved assembler
`bootFinalState`. `baseline_bootstrap_timeout` exposes the corresponding
finite prefix result and unchanged FFI state. This uses `challengeEvaluate`
itself, including its instruction checks and fixed memory/FFI boundaries.

The final instantiation must specialize the FFI type before assuming the
polymorphic simulation theorem: specializing an already-assumed proposition
would change a hypothesis. The checked script performs this specialization on
the closed theorem instead.

## Source memory, configuration, and native proof components

`initBootstrapSourceMemoryTheory` passed a clean build (32 s), proving the five
fixed source header words and preservation above those headers.
`initBaselineSourceMemoryTheory` passed (85 s): for every address in
`ordinaryDomain`, packing the eight final machine bytes produces exactly the
word in fixed `sourceMemory`. This includes the zeroed ordinary heap beyond
the headers. The challenge source definitions were not changed.

`initBackendConfigTheory` passed (73 s), proving backend configuration validity
and the initial machine-configuration premise for the exact compiler input.
`initChallengeNopTheory` passed (16 s), extending normal instruction simulation
to compiler padding while retaining the companion interference-search equality.

`initNoInstallTheory` passed (79 s). `guestLabProgram` follows the same
word-to-word, word-to-stack, and stack-to-lab pipeline as the resource-aware
compiler, and `guest_lab_no_install` proves the absence of lab-level dynamic
installation. The upstream theorem is explicitly specialized to 64-bit source
words; its lab-language conclusion alone does not determine that type.

`initMachineReturnTheory` passed (15 s). It proves the assembler/target
relations for the fixed external-call return and MMIO read/write returns,
including alignment and the MMIO destination register bound. The disabled
floating-point register clauses are discharged using the fixed RISC-V config.

These are closed, tag-checked proof components. The full native execution
connection, FFI/compiler installation obligations, sufficient stack/resource
bounds, full `Certificate`, and positive article replay remain to be proved.
In particular, the generic CakeML installation callback obligation does not
hold for the fixed cache-hook callback. The no-install result is a premise for
bridging that semantic difference, not a completed bridge.


## FFI installation and an auxiliary compiler configuration

`initFfiInstallationTheory` passed a clean build (18 s).
`admitted_ffi_interference` proves CakeML's `ffi_interfer_ok` for every admitted
submission using the fixed challenge callbacks. Admission supplies the exact
external/MMIO boundary, MMIO register bounds, and aligned return addresses;
`mmio_info_before_boundary` rules out MMIO metadata for external calls.

`initChallengeConfigTheory` passed (16 s).
`challenge_install_callback_irrelevant` proves, for every fuel and machine/FFI
state, that changing only `install_interfer` leaves `challengeEvaluate`
unchanged. The fuel induction unfolds both sides explicitly, uses unchanged
FFI-array reads, and commutes installation-callback updates past next/FFI
interference updates.

`initCompilerMachineTheory` passed (18 s). Its auxiliary
`compilerMachineConfig` supplies the callback required by the upstream
compiler theorem: copy the already-read bytes, return to the link register,
and return the destination address in register 10. The theory proves
`install_interfer_ok`, preserves the proved FFI condition, and establishes
exact equality of its `challengeEvaluate` results with `submissionConfig`.
The fixed challenge files and verifier statement are unchanged.

This does not establish equality of upstream `targetSem.evaluate` and the
cache-hook evaluator. A native simulation using the no-install property is
still required, along with the remaining memory/bitmap installation and
resource obligations, before a full Certificate or positive replay is claimed.


## Packed source memory and copied bitmap bytes

`initPackedMemoryTheory` passed a clean build (31 s). It constructs a total
64-bit word view of the actual machine byte memory and proves the compiler's
byte/word correspondence, including addresses that are not word aligned.
`initBaselinePackedMemoryTheory` passed (84 s): on every ordinary source
address, that view of native-entry memory agrees with the fixed source memory,
using the source-to-word value conversion.

`initBootWordBytesTheory` passed (75 s), proving little-endian word recovery
and indexing/slicing of flattened word encodings. `initBitmapFrameTheory`
passed (31 s), proving that the bootstrap's header stores preserve the copied
bitmap bytes. `initBaselineBitmapBytesTheory` passed (88 s): every byte in the
bitmap portion of the concrete native-entry memory equals the corresponding
byte of the fixed ROM data image.

`initWordListMemoryTheory` passed (9 s). Its generic lemma constructs a
separated `word_list` from indexed memory equalities over the exact generated
address domain. These theorems are closed and tag checked. Reconstruction of
the concrete bitmap word allocation and the remaining installation,
native-simulation, resource-bound, Certificate, and positive-replay obligations
are still pending.


## Exact native-entry bitmap allocation and target configuration

`initBaselineBitmapWordsTheory` passed a clean build (98 s), reconstructing
each of the 4,613 compiled bitmap words from the copied machine bytes.
`initBitmapDomainTheory` passed (29 s): its aligned byte domain is exactly the
word-address image, and the byte domain is closed under alignment.
`initWordListMemoryTheory` then connects indexed memory equalities to the
compiler's separated word-list predicate. `initBaselineBitmapInstalledTheory`
passed (95 s), establishing the exact bitmap allocation and empty data stack
in that predicate.

`initDataDomainTheory` passed (31 s), proving heap/stack alignment closure,
separation from the bitmap region, and disjointness of both ordinary regions
from shared I/O memory. `initBaselineConfiguredTheory` passed (91 s): the
proved bootstrap execution preserves the memory domain, link-register index,
instruction alignment, and endianness, and the resulting native-entry state
satisfies `target_configured` for the auxiliary compiler machine.

All results are closed and tag checked. The complete `pan_installed` contract,
native no-install simulation, stack/resource bounds, full Certificate, and
positive article replay remain outstanding.


`initBaselineDataDomainTheory` passed a clean build (86 s). The entire
heap/stack and bitmap byte-domain union is contained in the baseline program
domain and, using the proved bootstrap constants, in the actual native-entry
assembler memory domain. This discharges the data-domain containment component
of `good_init_state`; the full installation contract is still incomplete.


## Native code placement and shared-memory setup

`initCodeMemoryTheory` passed a clean build (14 s). It derives separated code
installation from indexed byte facts and proves exact `read_bytearray` recovery
and `code_loaded` from a related target state. `initBaselineCodeMemoryTheory`
passed (93 s): the native image is disjoint from ordinary data, the 760-byte
code buffer is installed outside that data domain, the size does not wrap,
and every target state related to the native-entry assembler state has the
exact compiled code loaded.

`initFfiBoundaryTheory` passed (15 s), proving that admission's name-boundary
predicate selects exactly the compiler's external-call/MMIO boundary.
`initSharedDomainTheory` passed (33 s), proving alignment closure of shared I/O
memory, program/shared disjointness, and identity interference for the auxiliary
compiler configuration. The saved-PC layout and assembled `good_init_state`
proofs are still being checked; no full Certificate is claimed.

For the remaining resource obligation, the original Lean entry point is
`submission/InitECandidate/Proofs/SourceStackCertificate.lean`. It uses the
checker and proof in `Proofs/StackAnalysis/RankedBound.lean`: all direct calls
must target present functions of strictly smaller rank, all frames are at most
92 words, and an entry rank of 39 gives the bound `(39+1)*187 = 7480`. This is
evidence for implementing a compact HOL checker over the actual optimized
word program, not a checked HOL resource bound yet. The generated Lean stack
proof files need not be imported.


## Complete native-entry good_init_state

`initBaselineStartPcTheory` passed a clean build (91 s), checking the saved halt
and installation PCs, external dispatch slots, MMIO entries, alignment, and
exact name/entry lengths. Finite reserved-slot witnesses are discharged with
bounded existential evaluation after reducing set membership.

`initInstallationMetadataTheory` passed (77 s). `cv_compute` proves that the
checked decoded compiler configuration has exactly `SOME compiledFfiNames`
and `compiledMmio` in its lab configuration.

`initBaselineGoodInitTheory` passed (97 s). For any restricted machine state
related to the proved bootstrap final assembler state, it establishes the full
upstream `good_init_state` contract for the auxiliary compiler configuration,
the exact native bytes, 760-byte code buffer, packed word memory, ordinary
data allocation, and fixed shared I/O domain. This combines the checked target
setup, saved-PC layout, callbacks, code/data separation, byte/word relation,
and memory-domain closure/containment.

The enclosing `pan_installed` witness is still being checked. Native no-install
simulation, the resource bound, the full challenge Certificate, and positive
article replay remain outstanding.


## Complete native-entry pan_installed

`initBaselineMemoryHeadersTheory` passed a clean build (99 s), connecting the
five fixed startup headers to the packed native-entry memory without evaluating
the bootstrap again. `initBaselineMmioLayoutTheory` passed (95 s): `cv_compute`
checks the exact MMIO entry/exit layout, dispatch indices, and nonwrapping bound.

`initBaselineInstalledTheory` passed a clean build (109 s). For every restricted
target state related to the fixed bootstrap final assembler state,
`baseline_pan_installed` proves the complete upstream Pancake installation
predicate for the auxiliary compiler machine: exact native bytes, 760-byte
code buffer, 4613 bitmap words, zero extra data words, source memory, ordinary
and shared domains, startup headers, and MMIO metadata. All exported results
are closed and tag checked. The bootstrap challenge execution already produces
a state with the required target relation.

This completes installation. Native no-install simulation between the compiler
and fixed challenge evaluator, resource bounds, the full challenge Certificate,
and positive article replay remain outstanding.


## Challenge evaluator clock and observation properties

`initChallengeClockTheory` passed a clean build (30 s). It proves preservation
of non-timeout results when increasing the execution clock, monotonicity of
I/O event prefixes both from the initial state and between execution clocks,
and uniqueness of non-timeout results across clocks. All four theorems are
closed and tag checked for the fixed challenge evaluator, including its cache
hook. These are prerequisites for lifting native simulation to observable
challenge behavior; they do not yet establish the full Certificate.

`initLabSimulationHelpersTheory` passed a clean build (17 s), including explicit
closure and tag checks. It exposes 27 lemmas that were local to the pinned
CakeML compiler proof, covering encoded instruction bytes, byte arrays,
labels, and external-call indices. They support the no-install simulation
without changing the CakeML submodule. The full simulation is still under
proof development.
