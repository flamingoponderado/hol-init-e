# Checked native compiler artifacts

`native-riscv.bin` contains the 904,476 native bytes computed by HOL4 from the
fixed guest AST. `bitmaps.txt` contains 4,613 decimal word64 bitmap values;
`backend.conf` is CakeML's encoded output configuration. File hashes and pins
are in `manifest.json`.

The checked theorem `initArtifacts.exact_guest_riscv_compilation` states that
the top-level Pancake compiler returns the named bytes, bitmaps and decoded
configuration. Reproduce with:

```sh
python3 tools/build.py --hol /path/to/tested/HOL initArtifactsTheory.uo
cmp .build/compiled.bin artifacts/native-riscv.bin
cmp .build/bitmaps.txt artifacts/bitmaps.txt
cmp .build/backend.conf artifacts/backend.conf
```

The files are exported from the checked CV results. Their SHA-256 hashes are
external integrity checks, not HOL cryptographic proofs.

**This is not a challenge submission.** The native code still needs a bootstrap
and a proof of installation from the challenge's zero-RAM initial state. No
`Certificate` proof or score is claimed for these files. The fixed source,
restricted machine and verifier are separate from this baseline development.
