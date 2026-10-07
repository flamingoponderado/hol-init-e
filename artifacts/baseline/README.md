# Candidate baseline ROM — certificate not yet proved

The 950,336-byte ROM combines the 208-byte bootstrap, padding to native entry
0x80000400, the checked native compiler output, and initialization data at
0x800df000. The bootstrap copies that data into zero-initialized RAM, sets the
heap/stack pointers and source headers, and jumps to native code.

`initBootstrap` checks the encoding, instruction admissibility under the
assembler configuration, and numeric layout. `initBaselineRom` proves the ROM
length, exact placement of native bytes/data, and that the native image fits
below the fixed source code buffer. Both theories passed isolated HOL builds.

Bootstrap execution, machine admission and the complete challenge Certificate
are still unproved. These files are development artifacts, not a verified
submission; no score or certificate article is supplied.

The normal build target is `initBaselineRomTheory.uo`. Exported files are named
`bootstrap.bin` and `baseline-rom.bin` in the build directory. Integrity hashes
are in `manifest.json`; these hashes are external checks, not HOL theorems.
