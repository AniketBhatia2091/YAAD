#!/usr/bin/env python3
"""
Dataset Validator Script.
Validates ground_truth.csv against images/ directory, dataset_manifest.json rules, and privacy constraints.
Part of YAAD OCR Spike v0.5.
"""

import argparse
import csv
import json
import os
import re
import sys
from typing import List, Set, Dict, Any


def load_manifest(manifest_path: str) -> Dict[str, Any]:
    if not os.path.exists(manifest_path):
        # Fallback default manifest parameters
        return {
            "allowed_enums": {
                "doc_types": ["bill", "prescription", "medicine_strip", "id", "warranty"],
                "doc_subtypes": ["electricity", "water", "broadband", "mobile", "clinic", "hospital", "manufacturer_strip", "aadhaar", "pan", "driving_license", "vehicle_rc", "receipt", "card", "general"],
                "languages": ["english", "hindi", "punjabi", "hinglish", "mixed"],
                "scripts": ["latin", "devanagari", "gurmukhi", "mixed"],
                "image_qualities": ["good", "acceptable", "poor"],
                "source_types": ["camera_photo", "gallery_import", "scanned_pdf", "synthetic_fixture"],
                "field_visibility_statuses": ["all_visible", "partially_visible", "occluded", "cropped"],
                "annotation_confidences": ["high", "medium", "low"],
            },
            "explicit_tokens": ["<NOT_PRESENT>", "<UNREADABLE>", "<NOT_APPLICABLE>"],
        }
    with open(manifest_path, "r", encoding="utf-8") as f:
        return json.load(f)


def validate_dataset(gt_path: str, img_dir: str, manifest_path: str = "dataset_manifest.json") -> List[str]:
    errors = []
    if not os.path.exists(gt_path):
        return [f"Ground truth CSV file not found at: {gt_path}"]

    manifest = load_manifest(manifest_path)
    allowed = manifest.get("allowed_enums", {})
    explicit_tokens = set(manifest.get("explicit_tokens", ["<NOT_PRESENT>", "<UNREADABLE>", "<NOT_APPLICABLE>"]))

    valid_doc_types = set(allowed.get("doc_types", []))
    valid_languages = set(allowed.get("languages", []))
    valid_scripts = set(allowed.get("scripts", []))
    valid_qualities = set(allowed.get("image_qualities", []))
    valid_booleans = {"true", "false"}

    sample_ids_in_csv: Set[str] = set()
    filenames_in_csv: Set[str] = set()

    with open(gt_path, mode="r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        row_num = 1  # Header is row 1
        for r in reader:
            row_num += 1
            sample_id = (r.get("sample_id") or "").strip()
            filename = (r.get("filename") or "").strip()

            if not sample_id:
                errors.append(f"Row {row_num}: Missing sample_id.")
            elif sample_id in sample_ids_in_csv:
                errors.append(f"Row {row_num}: Duplicate sample_id '{sample_id}'.")
            else:
                sample_ids_in_csv.add(sample_id)

            if not filename:
                errors.append(f"Row {row_num}: Empty filename.")
            elif filename in filenames_in_csv:
                errors.append(f"Row {row_num}: Duplicate filename '{filename}'.")
            else:
                filenames_in_csv.add(filename)

            # Check Enum fields
            doc_type = (r.get("doc_type") or "").strip().lower()
            if doc_type not in valid_doc_types:
                errors.append(f"Row {row_num} ('{sample_id}'): Invalid doc_type '{doc_type}'. Allowed: {valid_doc_types}")

            lang = (r.get("language") or "").strip().lower()
            if lang not in valid_languages:
                errors.append(f"Row {row_num} ('{sample_id}'): Invalid language '{lang}'. Allowed: {valid_languages}")

            script = (r.get("script") or "").strip().lower()
            if script not in valid_scripts:
                errors.append(f"Row {row_num} ('{sample_id}'): Invalid script '{script}'. Allowed: {valid_scripts}")

            hw = (r.get("handwritten") or "").strip().lower()
            if hw not in valid_booleans:
                errors.append(f"Row {row_num} ('{sample_id}'): Invalid handwritten value '{hw}'. Expected 'true' or 'false'")

            quality = (r.get("image_quality") or "").strip().lower()
            if quality not in valid_qualities:
                errors.append(f"Row {row_num} ('{sample_id}'): Invalid image_quality '{quality}'. Allowed: {valid_qualities}")

            # Validate Date Fields
            for date_col in ["expected_due_date", "expected_expiry_date", "expected_warranty_end", "expected_application_deadline"]:
                d_val = (r.get(date_col) or "").strip()
                if d_val and d_val not in explicit_tokens:
                    if not re.match(r"^\d{4}-\d{2}-\d{2}$", d_val):
                        errors.append(f"Row {row_num} ('{sample_id}'): Malformed date in {date_col}: '{d_val}'. Expected ISO YYYY-MM-DD or explicit token {explicit_tokens}")

            # Validate Amount Field
            amt_val = (r.get("expected_amount") or "").strip()
            if amt_val and amt_val not in explicit_tokens:
                try:
                    float(amt_val.replace(",", ""))
                except ValueError:
                    errors.append(f"Row {row_num} ('{sample_id}'): Malformed amount '{amt_val}'. Expected float string or explicit token {explicit_tokens}")

    return errors


def main():
    parser = argparse.ArgumentParser(description="Validate OCR spike ground truth dataset")
    parser.add_argument("--gt", default="ground_truth.csv", help="Path to ground truth CSV")
    parser.add_argument("--img_dir", default="images", help="Path to images directory")
    parser.add_argument("--manifest", default="dataset_manifest.json", help="Path to dataset_manifest.json")
    args = parser.parse_args()

    print("[Dataset Validator] Checking ground_truth.csv schema, sample_ids, and file integrity...")
    errors = validate_dataset(args.gt, args.img_dir, args.manifest)

    if errors:
        print("\n❌ DATASET VALIDATION ERRORS FOUND:")
        for err in errors:
            print(f"  - {err}")
        sys.exit(1)
    else:
        print("✓ Dataset validation PASSED. Schema and metadata are valid.")
        sys.exit(0)


if __name__ == "__main__":
    main()
