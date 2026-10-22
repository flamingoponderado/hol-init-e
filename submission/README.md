# Participant submissions (untrusted)

The only accepted participant format is a source envelope containing exactly:

```text
rom.bin
claim.json
experiments/*.sml
experiments/*.sig
```

`rom.bin` is arbitrary submitted RISC-V bytes, bounded to 128 MiB. `claim.json`
is exactly `{"K":123}` or `{"K":"infinity"}`. Proof source files must be flat
regular files with HOL module names. There is no participant-supplied
`certificate.art` path.

From the operator's pinned checkout, run:

```sh
python3 verifier/verify.py /path/to/source-submission \
  --hol /path/to/tested/HOL --author-hol /path/to/tracing/HOL \
  --work /path/to/new-work-directory
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

The current baseline source bundle is about 1.56 MB uncompressed (ROM plus 143
HOL source files), compared with the multi-gigabyte generated article. Reduced
Lean decoder and machine-step agreement remains a separate unproved
obligation; see [verifier documentation](../verifier/README.md).
