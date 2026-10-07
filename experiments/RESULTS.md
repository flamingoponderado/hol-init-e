# cv_compute experiment, 2026-10-07

Pins are in `../provenance.json`. The tested HOL checkout is `tested_hol`.
The sibling HOL checkout was also built, but is not the toolchain used for the
results below. No generated Lean proof module was copied or invoked; the source
submission has 56,017 Lean files.

## Passing results

| Target | Result | Observed Holmake time |
| --- | --- | --- |
| `initGuestTheory` | All 928 fixed declarations accepted as HOL definitions | 196 s |
| `panSimplifyCvTheory` | Generic 64-bit Pancake simplifier translated to cv | 28 s |
| `initSimplifyTheory` | Whole-guest simplification equality, no assumptions or admitted-proof tags | 88 s |
| `initParamsTheory` | Budget and memory-layout proofs | 8 s |
| `initTargetTheory` | Restricted decoder/step definitions and constructor/raw-word regressions | 18 s |

Times are observed build wall times, including load/export work, on this
workspace. They are not isolated performance benchmarks or full compilation
times. Cached dependencies were reused for some targets.

The two main exported computation results are:

```text
|- LENGTH guestAst = 928
|- pan_simp$compile_prog guestAst = simplified_guest
```

The full guest needs only a short registration loop over its literal definitions.
Record literals must first be rewritten to their datatype constructor, and
opaque `b2c` boolean encodings must be simplified. `cv_trans_deep_embedding`
then registers the literal data; `cv_eval_pat` performs the compiler pass and
names its evaluated result. All generated proof objects stay in ignored build
artifacts, rather than thousands of checked-in proof source files.

## Remaining compiler blocker (reproduced)

```sh
python3 tools/build.py --hol /path/to/tested/HOL panWordCvTheory.uo
```

This optional target currently fails at the termination proof for cv translation
of `pan_structs.compile_shape` and `compile_shapes`. Calling `cv_auto_trans` on
the entire pipeline first loops while discovering those mutually recursive
definitions. Registering the whole definition group eliminates that loop but
requires an explicit termination argument.

`panWordCvScript.sml` tries the source's lexicographic strategy: first the cv
size of the struct context, then the cv size of the shape or shape list. The
generic termination tactic leaves obligations, including that the tail of the
specialized `dropWhile` result is smaller than its input context when that
result is a pair. A size bound for that generated helper is needed. No axiom,
cheat, or assumed termination theorem was introduced to bypass this obligation.

`initWordScript.sml` is the downstream full-guest word-code experiment and
cannot build until `panWordCv` is completed. Neither target is in the passing
default build. There is no source-to-bytecode result or complete challenge
certificate yet.

## Verifier boundary

Six AST importer tests and eleven verifier boundary tests pass. Reimporting the
pinned Lean AST reproduces the checked-in HOL source byte for byte. The real
verifier checks the trusted snapshot and CakeML pin; a well-formed arbitrary ROM
and opaque proof artifact yield `incomplete`, exit 2. It never reports acceptance
while the fixed Certificate and independent proof checker are absent.
