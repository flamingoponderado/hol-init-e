import unittest
from import_allocation import encode

class AllocationImportTests(unittest.TestCase):
    def test_literal_tree_shape_and_entry_order(self):
        self.assertEqual(encode("def chunk := [some (Flapjack.Spt.bs Flapjack.Spt.ln 7 (Flapjack.Spt.ls 2)), none, some (Flapjack.Spt.bn Flapjack.Spt.ln Flapjack.Spt.ln)]\ntheorem size := ignored"),
            [["S", "Bs", "Ln", "7", "Ls", "2"], ["N"], ["S", "Bn", "Ln", "Ln"]])
    def test_unknown_syntax_rejected(self):
        with self.assertRaises(ValueError): encode("def chunk := [some (unsafe 17)]")
    def test_negative_colour_rejected(self):
        with self.assertRaises(ValueError): encode("def chunk := [some (Flapjack.Spt.ls -1)]")
    def test_extra_tokens_rejected(self):
        with self.assertRaises(ValueError): encode("def chunk := [none] [none]")

if __name__ == '__main__': unittest.main()
