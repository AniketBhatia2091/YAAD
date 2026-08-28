#!/usr/bin/env python3
"""
Scoring Engine, Confidence Calibration, and Failure Taxonomy Classifier.
Part of YAAD OCR & Structured Extraction Spike v0.3.
"""

import argparse
import csv
import json
import os
import sys
from typing import Dict, List, Any, Tuple

from common import (
    GroundTruthRow,
    load_ground_truth,
    match_date,
    match_numeric,
    match_text,
)


REQUIRED_FIELDS_BY_DOC = {
    "bill": ["expected_provider", "expected_amount", "expected_due_date"],
    "warranty": ["expected_provider", "expected_warranty_end"],
    "id": ["expected_title", "expected_person"],
    "medicine_strip": ["expected_medicine"],
    "prescription": ["expected_medicine", "expected_person"],
}


def evaluate_field(field_name: str, expected_val: str, actual_val: str) -> bool:
    """Evaluates field correctness using domain-specific fuzzy/semantic match rules."""
    if "amount" in field_name:
        return match_numeric(expected_val, actual_val)
    elif "date" in field_name or "end" in field_name or "deadline" in field_name:
        return match_date(expected_val, actual_val)
    else:
        return match_text(expected_val, actual_val)


def classify_failure_reason(row: GroundTruthRow, field_name: str, expected: str, actual: str, conf: float) -> str:
    """Classifies extraction failure into taxonomy category."""
    if not actual:
        return "missing_field"
    if conf > 0.85 and not match_text(expected, actual):
        return "hallucination"
    if row.handwritten:
        return "handwriting"
    if row.image_quality == "poor":
        return "blurry_or_glare"
    if row.script in ["devanagari", "gurmukhi", "mixed"]:
        return "language_script"
    if "date" in field_name:
        return "date_interpretation"
    if "amount" in field_name:
        return "numeric_interpretation"
    return "ocr_character_error"


def run_scoring(gt_csv: str, out_dir: str):
    gt_rows = load_ground_truth(gt_csv)
    raw_dir = os.path.join(out_dir, "tesseract_raw")
    enh_dir = os.path.join(out_dir, "tesseract_enhanced")
    vis_dir = os.path.join(out_dir, "vision")

    score_records = []
    failures = []
    calibration_buckets = {
        "0.0-0.49": {"correct": 0, "total": 0},
        "0.50-0.69": {"correct": 0, "total": 0},
        "0.70-0.84": {"correct": 0, "total": 0},
        "0.85-0.94": {"correct": 0, "total": 0},
        "0.95-1.00": {"correct": 0, "total": 0},
    }

    methods = ["tesseract_raw", "tesseract_enhanced", "vision"]

    for row in gt_rows:
        safe_name = row.filename.replace("/", "_")

        for method in methods:
            actual_fields: Dict[str, Any] = {}
            conf_fields: Dict[str, float] = {}

            if method == "vision":
                v_path = os.path.join(vis_dir, f"{safe_name}.json")
                if os.path.exists(v_path):
                    with open(v_path, "r", encoding="utf-8") as f:
                        data = json.load(f)
                        actual_fields = data.get("fields", {})
                        conf_fields = data.get("confidence", {})
            else:
                t_path = os.path.join(raw_dir if method == "tesseract_raw" else enh_dir, f"{safe_name}.txt")
                if os.path.exists(t_path):
                    with open(t_path, "r", encoding="utf-8") as f:
                        text = f.read()
                        actual_fields = {"raw_text": text}

            # Map GT expected fields
            gt_field_map = {
                "expected_title": row.expected_title,
                "expected_amount": row.expected_amount,
                "expected_due_date": row.expected_due_date,
                "expected_expiry_date": row.expected_expiry_date,
                "expected_document_number": row.expected_document_number,
                "expected_person": row.expected_person,
                "expected_medicine": row.expected_medicine,
                "expected_dosage": row.expected_dosage,
                "expected_provider": row.expected_provider,
                "expected_policy_number": row.expected_policy_number,
                "expected_warranty_end": row.expected_warranty_end,
                "expected_application_deadline": row.expected_application_deadline,
            }

            req_fields = REQUIRED_FIELDS_BY_DOC.get(row.doc_type, ["expected_title"])
            doc_success = True
            doc_eval_count = 0

            for f_name, exp_val in gt_field_map.items():
                if not exp_val:
                    continue  # N/A

                doc_eval_count += 1
                short_key = f_name.replace("expected_", "")
                act_val = actual_fields.get(short_key) or actual_fields.get(f_name)
                conf_val = float(conf_fields.get(short_key, 0.5))

                is_correct = evaluate_field(f_name, exp_val, str(act_val) if act_val else "")

                if not is_correct and f_name in req_fields:
                    doc_success = False

                # Calibration binning
                if conf_val < 0.50:
                    bucket = "0.0-0.49"
                elif conf_val < 0.70:
                    bucket = "0.50-0.69"
                elif conf_val < 0.85:
                    bucket = "0.70-0.84"
                elif conf_val < 0.95:
                    bucket = "0.85-0.94"
                else:
                    bucket = "0.95-1.00"

                calibration_buckets[bucket]["total"] += 1
                if is_correct:
                    calibration_buckets[bucket]["correct"] += 1

                score_records.append({
                    "method": method,
                    "filename": row.filename,
                    "doc_type": row.doc_type,
                    "language": row.language,
                    "script": row.script,
                    "handwritten": row.handwritten,
                    "image_quality": row.image_quality,
                    "field_name": f_name,
                    "expected": exp_val,
                    "actual": act_val or "",
                    "is_correct": is_correct,
                    "confidence": conf_val,
                })

                if not is_correct:
                    reason = classify_failure_reason(row, f_name, exp_val, str(act_val) if act_val else "", conf_val)
                    failures.append({
                        "method": method,
                        "filename": row.filename,
                        "doc_type": row.doc_type,
                        "field_name": f_name,
                        "expected": exp_val,
                        "actual": act_val or "",
                        "confidence": conf_val,
                        "failure_category": reason,
                    })

    # Save score_results.csv
    score_path = os.path.join(out_dir, "score_results.csv")
    if score_records:
        with open(score_path, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=score_records[0].keys())
            writer.writeheader()
            writer.writerows(score_records)

    # Save failure_analysis.csv
    fail_path = os.path.join(out_dir, "failure_analysis.csv")
    if failures:
        with open(fail_path, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=failures[0].keys())
            writer.writeheader()
            writer.writerows(failures)

    # Print Calibration Summary
    print("\n--- Confidence Calibration Matrix ---")
    for bucket, counts in calibration_buckets.items():
        tot = counts["total"]
        acc = (counts["correct"] / tot * 100) if tot > 0 else 0.0
        print(f"Bucket {bucket}: {counts['correct']}/{tot} ({acc:.1f}% accuracy)")

    return score_records, failures, calibration_buckets


def main():
    parser = argparse.ArgumentParser(description="Score OCR spike results")
    parser.add_argument("--gt", default="ground_truth.csv", help="Path to ground truth CSV")
    parser.add_argument("--out_dir", default="outputs", help="Output directory")
    args = parser.parse_args()

    run_scoring(args.gt, args.out_dir)


if __name__ == "__main__":
    main()
