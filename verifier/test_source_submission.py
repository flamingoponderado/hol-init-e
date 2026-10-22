"""Boundary tests for the sole source-based participant envelope."""
from pathlib import Path
import tempfile
import unittest
from verify_source import frozen_source_submission


class SourceSubmissionTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='hol-init-source-test-')
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.candidate = self.base/'candidate'
        self.candidate.mkdir()
        (self.candidate/'rom.bin').write_bytes(b'\x13\x00\x00\x00')
        (self.candidate/'claim.json').write_text('{"K":"infinity"}\n')
        (self.candidate/'experiments').mkdir()
        (self.candidate/'experiments'/'initProofScript.sml').write_text(
            'Theorem candidate_proof: T \\n+               \\n+  Proof simp[] QED\n')
        self.snapshot = self.base/'snapshot'
        self.snapshot.mkdir()

    def test_valid_source_is_frozen_without_article(self):
        score = frozen_source_submission(self.candidate, self.snapshot)
        self.assertEqual(score, 'infinity')
        self.assertEqual((self.snapshot/'rom.bin').read_bytes(), b'\x13\x00\x00\x00')
        self.assertEqual((self.snapshot/'claim.json').read_text(), '{"K":"infinity"}\n')
        self.assertEqual((self.snapshot/'experiments'/'initProofScript.sml').read_text(),
                         (self.candidate/'experiments'/'initProofScript.sml').read_text())
        self.assertNotIn('certificate.art', {p.name for p in self.snapshot.iterdir()})

    def test_article_file_is_not_a_source_envelope(self):
        (self.candidate/'certificate.art').write_bytes(b'article')
        with self.assertRaisesRegex(ValueError, 'exactly rom.bin, claim.json, experiments'):
            frozen_source_submission(self.candidate, self.snapshot)

    def test_duplicate_claim_field_is_rejected(self):
        (self.candidate/'claim.json').write_text('{"K":"infinity","K":1}')
        with self.assertRaisesRegex(ValueError, 'duplicate JSON key'):
            frozen_source_submission(self.candidate, self.snapshot)

    def test_symlink_source_is_rejected(self):
        source = self.candidate/'experiments'/'initProofScript.sml'
        source.unlink()
        source.symlink_to(self.candidate/'claim.json')
        with self.assertRaisesRegex(ValueError, 'regular files'):
            frozen_source_submission(self.candidate, self.snapshot)


if __name__ == '__main__':
    unittest.main()
