# Participant submissions (untrusted)

The only accepted participant format is a source envelope containing exactly:

```text
rom.bin
claim.json
experiments/*.sml
experiments/*.sig
experiments/original-allocation.term
```

`rom.bin` is arbitrary submitted RISC-V bytes, bounded to 128 MiB. `claim.json`
is exactly `{"K":123}` or `{"K":"infinity"}`. Proof source files must be flat
regular files with HOL module names. There is no participant-supplied
`certificate.art` path.

`original-allocation.term` is the untrusted register-allocation hint consumed
by the baseline compiler source. HOL checks the hint against the compiled
program; it is data, not an accepted proof or trusted certificate.

From the operator's pinned checkout, run:

```sh
python3 verifier/verify.py /path/to/source-submission \
  --hol /path/to/tested/HOL --author-hol /path/to/tracing/HOL \
  --work /path/to/new-work-directory --source-timeout 28800
```

The source is frozen, then run in an isolated author-side tracing HOL process.
That process generates an OpenTheory article locally. The operator then checks
the exact ROM and score literals against the fixed `Certificate` using the
ordinary strict kernel replay in a separate process. Only that replay can
return `verified`; source execution and article generation alone are not
acceptance. The article-only checker is an internal implementation stage, not
a second participant submission route.

The fixed challenge is not participant-editable. Dispatch/layout metadata is
an admitted existential witness in the proof, not a replacement challenge
configuration. The source protocol currently targets the baseline
`initBaselineCertificate` theory tree.

The current baseline source bundle is about 2.83 MB uncompressed (ROM, 143 HOL
source files, and the allocation hint), or 655,407 bytes as a level-9 DEFLATE
ZIP archive. Extract an archive before invoking the verifier; direct ZIP input
is not supported. The generated article is 2.80 GB and stays operator-side.
The [source verification record](../artifacts/baseline/source-submission-verification.json)
records successful independent replay after staged export/replay continuations. Reduced
Lean decoder and machine-step agreement remains a separate unproved
obligation; see [verifier documentation](../verifier/README.md).
