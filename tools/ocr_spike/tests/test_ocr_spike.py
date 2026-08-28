import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "scripts"))

from common import (
    load_ground_truth,
    match_date,
    match_numeric,
    match_strict_identifier,
    match_strict_text,
    match_text,
    normalize_date,
    normalize_numeric,
    normalize_text,
)
from stage1_preprocessing import analyze_image_quality
from stage3_parsing import run_stage3_parsing
from stage4_mapping import run_stage4_mapping
from stage5_hallucination import run_stage5_hallucination_check
from vision_providers import (
    AnthropicVisionProvider,
    GenericRestVisionProvider,
    GoogleVisionProvider,
    OpenAIVisionProvider,
    get_vision_provider,
)


class TestOcrSpikeHarness(unittest.TestCase):

    def test_normalize_text_preserves_scripts(self):
        self.assertEqual(normalize_text("  Electricity   BILL!  "), "electricity bill!")
        self.assertEqual(normalize_text("  बिजली   बिल  "), "बिजली बिल")
        self.assertEqual(normalize_text("  ਬਿਜਲੀ ਬਿਲ  "), "ਬਿਜਲੀ ਬਿਲ")

    def test_strict_identifier_matching(self):
        self.assertTrue(match_strict_identifier("ACC-102938475", "acc 102938475"))
        self.assertTrue(match_strict_identifier("102938475", "1029-3847-5"))
        self.assertFalse(match_strict_identifier("ACC-102938475", "ACC-999999999"))
        self.assertFalse(match_strict_identifier("ACC-102938475", "1029"))  # Loose substring rejected!

    def test_strict_numeric_matching(self):
        self.assertTrue(match_numeric("₹1,847.00", "1847.00"))
        self.assertTrue(match_numeric("Rs 1847/-", "1847"))
        self.assertFalse(match_numeric("1847.00", "1848.00"))

    def test_strict_date_matching(self):
        self.assertTrue(match_date("05/09/2026", "2026-09-05"))
        self.assertTrue(match_date("5 Sep 2026", "05/09/2026"))
        self.assertFalse(match_date("2026-09-05", "2026-09-06"))

    def test_strict_text_matching(self):
        self.assertTrue(match_strict_text("Crocin 650mg", "crocin 650mg"))
        self.assertFalse(match_strict_text("Crocin 650mg", "Crocin"))

    def test_stage3_parsing(self):
        raw_text = "BSES Yamuna Power Limited\nAmount Due: ₹1,847.00\nDue Date: 05/09/2026\nAccount No: 102938475"
        parsed = run_stage3_parsing(raw_text)
        self.assertEqual(parsed["parsed_fields"].get("amount"), "1847.00")
        self.assertEqual(parsed["parsed_fields"].get("due_date"), "05/09/2026")
        self.assertEqual(parsed["parsed_fields"].get("document_number"), "102938475")

    def test_stage4_mapping(self):
        parsed = {"amount": "1847.00", "due_date": "05/09/2026", "document_number": "102938475"}
        mapped = run_stage4_mapping(parsed)
        self.assertEqual(mapped["amount"], "1847.00")
        self.assertEqual(mapped["due_date"], "05/09/2026")
        self.assertEqual(mapped["document_number"], "102938475")
        self.assertIsNone(mapped["person"])

    def test_stage5_hallucination_detection(self):
        raw_text = "BSES Yamuna Power Limited Amount: ₹1847.00"
        mapped = {"amount": "1847.00", "person": "Fake John Doe"}
        confidence = {"amount": 0.95, "person": 0.92}

        anomalies = run_stage5_hallucination_check(mapped, raw_text, confidence)
        self.assertEqual(len(anomalies), 1)
        self.assertEqual(anomalies[0]["field_name"], "person")
        self.assertEqual(anomalies[0]["anomaly_type"], "hallucination")

    def test_vision_providers_configuration(self):
        # Factory defaults
        provider, p_type, p_model = get_vision_provider()
        self.assertIn(p_type, ["google", "openai", "anthropic", "generic_rest"])

    def test_load_ground_truth(self):
        gt_path = os.path.join(os.path.dirname(__file__), "..", "ground_truth_template.csv")
        if os.path.exists(gt_path):
            rows = load_ground_truth(gt_path)
            self.assertGreater(len(rows), 0)
            self.assertEqual(rows[0].doc_type, "bill")


if __name__ == "__main__":
    unittest.main()
