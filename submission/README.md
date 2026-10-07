# Participant submissions (untrusted)

Put a candidate in its own directory outside the trusted challenge tree:

- `rom.bin`: arbitrary submitted bytes, at most 128 MiB.
- `claim.json`: exactly `{"K":123}` or `{"K":"infinity"}`.
- `certificate.art`: an OpenTheory article proving the exact fixed certificate.

The operator runs `python3 verifier/verify.py /path/to/candidate --replay` after
preparing the fixed verifier heap. The bytes and score are frozen and sanitized
into literal HOL definitions. Acceptance requires a closed proof of precisely
`initChallenge.Certificate submittedBytes submittedScore`.

The fixed challenge is not participant-editable. Candidate code is never added
to the trusted HOL load path. Dispatch/layout metadata is an admitted existential
witness in the proof, not a replacement challenge configuration.

No complete baseline certificate is available yet. The compiler's native output
still needs a proved bootstrap/installation and semantic correctness bridge.
See [verifier documentation](../verifier/README.md).
