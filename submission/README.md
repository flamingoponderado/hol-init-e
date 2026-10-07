# Participant submissions (untrusted)

Put a candidate in its own directory, outside the trusted challenge tree:

- `rom.bin`: literal arbitrary submitted bytes, at most 128 MiB.
- `claim.json`: exactly `{"K":123}` or `{"K":"infinity"}`.
- `certificate.art`: a proposed proof artifact; proof replay is not implemented.

Run the operator's `verifier/verify.py` on that directory. Current preflight can
reject malformed envelopes but cannot accept a submission. No baseline
certificate or bytecode is claimed here yet. `experiments/` contains development
work toward the baseline and is not a participant extension to the challenge.

The fixed challenge and target semantics are not participant-editable. Candidate
code must not be added to the trusted HOL load path. Future proof acceptance must
bind exactly the submitted bytes, score, and metadata to the fixed certificate.
