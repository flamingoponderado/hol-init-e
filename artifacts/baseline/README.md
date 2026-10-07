# Candidate baseline ROM — certificate not yet proved

The 950,336-byte ROM combines the 208-byte bootstrap, padding to native entry
`0x80000fec`, the checked 904,476-byte native compiler output, and initialization
data at `0x800df000`. The native image ends exactly at `0x800ddd08`, as required
by the fixed source-memory code-buffer header. The bootstrap copies the data
into zero-initialized RAM, sets the heap/stack pointers and source headers, and
jumps to native code.

`initBootstrap` checks encoding, assembler instruction admissibility, and
numeric layout. `initBaselineRom` proves the ROM length, exact native/data
placement, and `native_ends_at_fixed_buffer`. `initBaselineAdmission` proves
admission of the resulting submission. These theories passed clean builds for
this placement. Execution-proof details and remaining obligations are tracked
in `experiments/RESULTS.md`.

The full challenge Certificate is still unproved. These are development
artifacts, not a verified submission; no score or certificate article is supplied.

The construction target is `initBaselineRomTheory`. Exported files are named
`bootstrap.bin` and `baseline-rom.bin` in the build directory. Integrity hashes
are in `manifest.json`; these hashes are external checks, not HOL theorems.
