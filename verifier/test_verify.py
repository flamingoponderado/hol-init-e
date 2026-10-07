import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import verify

class BoundaryTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.candidate = Path(self.tmp.name)
        (self.candidate/'claim.json').write_text('{"K":"infinity"}')
        (self.candidate/'rom.bin').write_bytes(bytes([0xff, 0, 1]))
        (self.candidate/'certificate.art').write_text('untrusted proof bytes')

    def test_arbitrary_bytes_pass_only_preflight(self):
        self.assertEqual(verify.preflight(self.candidate)['rom_bytes'], 3)
        with patch.object(verify, 'check_trusted'), patch('builtins.print') as output:
            self.assertEqual(verify.main([str(self.candidate)]), 2)
        self.assertEqual(json.loads(output.call_args.args[0])['status'], 'incomplete')

    def test_extra_code_is_rejected(self):
        (self.candidate/'evil.sml').write_text('raise Fail "must never execute"')
        with self.assertRaises(verify.Rejected): verify.preflight(self.candidate)

    def test_symlink_rom_rejected(self):
        (self.candidate/'rom.bin').unlink()
        (self.candidate/'rom.bin').symlink_to('/etc/passwd')
        with self.assertRaises(OSError): verify.preflight(self.candidate)

    def test_boolean_score_rejected(self):
        (self.candidate/'claim.json').write_text('{"K":true}')
        with self.assertRaises(verify.Rejected): verify.preflight(self.candidate)

    def test_duplicate_score_rejected(self):
        (self.candidate/'claim.json').write_text('{"K":0,"K":"infinity"}')
        with self.assertRaises(verify.Rejected): verify.preflight(self.candidate)

    def test_negative_score_rejected(self):
        (self.candidate/'claim.json').write_text('{"K":-1}')
        with self.assertRaises(verify.Rejected): verify.preflight(self.candidate)

    def test_oversize_rom_rejected(self):
        with patch.object(verify, 'ROM_LIMIT', 2):
            with self.assertRaises(verify.Rejected): verify.preflight(self.candidate)

    def test_directory_in_place_of_proof_rejected(self):
        (self.candidate/'certificate.art').unlink()
        (self.candidate/'certificate.art').mkdir()
        with self.assertRaises((OSError, verify.Rejected)): verify.preflight(self.candidate)

    def trusted_tree(self):
        root = self.candidate/'trusted'
        (root/'verifier').mkdir(parents=True)
        (root/'challenge').mkdir()
        (root/'challenge/fixed.sml').write_text('fixed challenge')
        digest = hashlib.sha256(b'fixed challenge').hexdigest()
        (root/'verifier/trusted-files.json').write_text(json.dumps({'challenge/fixed.sml':digest}))
        (root/'provenance.json').write_text('{"cakeml":"pinned"}')
        return root

    def test_modified_challenge_rejected(self):
        root = self.trusted_tree()
        (root/'challenge/fixed.sml').write_text('participant replacement')
        with patch.object(verify, 'ROOT', root):
            with self.assertRaisesRegex(verify.Rejected, 'modified trusted'):
                verify.check_trusted()

    def test_injected_challenge_module_rejected(self):
        root = self.trusted_tree()
        (root/'challenge/extraScript.sml').write_text('untrusted code')
        with patch.object(verify, 'ROOT', root):
            with self.assertRaisesRegex(verify.Rejected, 'unexpected trusted file set'):
                verify.check_trusted()

    def test_wrong_dependency_pin_rejected(self):
        root = self.trusted_tree()
        with patch.object(verify, 'ROOT', root), patch('subprocess.check_output', return_value='wrong'):
            with self.assertRaisesRegex(verify.Rejected, 'pin differs'):
                verify.check_trusted()

if __name__ == '__main__': unittest.main()
