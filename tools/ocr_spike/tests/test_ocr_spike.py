import os
import sys
import unittest

# Add scripts directory to python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "scripts"))

from common import (
    load_ground_truth,
    match_date,
    match_numeric,
    match_text,
    normalize_date,
    normalize_numeric,
    normalize_text,
)


class TestOcrSpikeHarness(unittest.TestCase):

    def test_normalize_text_preserves_scripts(self):
        # English
        self.assertEqual(normalize_text("  Electricity   BILL!  "), "electricity bill!")
        # Hindi Devanagari script preservation
        self.assertEqual(normalize_text("  बिजली   बिल  "), "बिजली बिल")
        # Punjabi Gurmukhi script preservation
        self.assertEqual(normalize_text("  ਬਿਜਲੀ ਬਿਲ  "), "ਬਿਜਲੀ ਬਿਲ")

    def test_normalize_numeric(self):
        self.assertEqual(normalize_numeric("₹1,847.00"), 1847.0)
        self.assertEqual(normalize_numeric("Rs 1847/-"), 1847.0)
        self.assertEqual(normalize_numeric("INR 450"), 450.0)
        self.assertIsNone(normalize_numeric(""))
        self.assertIsNone(normalize_numeric(None))

    def test_match_numeric(self):
        self.assertTrue(match_numeric("₹1,847.00", "1847"))
        self.assertTrue(match_numeric("1847.00", "Rs 1847/-"))
        self.assertFalse(match_numeric("1847", "2000"))

    def test_normalize_date(self):
        self.assertEqual(normalize_date("05/09/2026"), "2026-09-05")
        self.assertEqual(normalize_date("2026-09-05"), "2026-09-05")
        self.assertEqual(normalize_date("5 Sep 2026"), "2026-09-05")

    def test_match_date(self):
        self.assertTrue(match_date("05/09/2026", "2026-09-05"))
        self.assertTrue(match_date("5 Sep 2026", "05/09/2026"))
        self.assertFalse(match_date("2026-09-05", "2026-10-15"))

    def test_match_text_fuzzy(self):
        self.assertTrue(match_text("BSES Yamuna Power Limited", "bses yamuna"))
        self.assertTrue(match_text("Thyronorm 50mcg", "thyronorm 50mcg"))
        self.assertFalse(match_text("Apollo Hospital", "Max Healthcare"))

    def test_load_ground_truth(self):
        gt_path = os.path.join(os.path.dirname(__file__), "..", "ground_truth_template.csv")
        if os.path.exists(gt_path):
            rows = load_ground_truth(gt_path)
            self.assertGreater(len(rows), 0)
            self.assertEqual(rows[0].doc_type, "bill")


if __name__ == "__main__":
    unittest.main()
