#!/usr/bin/env python3
"""
Dataset Statistics & Target Checker Tool.
Generates dataset_stats.csv and dataset_stats.md.
Part of YAAD OCR Spike v0.4.
"""

import argparse
import csv
import os
import sys
from collections import defaultdict
from typing import Dict, List, Any

from common import load_ground_truth

TARGET_DISTRIBUTION = {
    ("bill", "all"): 12,
    ("prescription", "printed"): 8,
    ("prescription", "handwritten"): 8,
    ("medicine_strip", "all"): 10,
    ("id", "all"): 8,
    ("warranty", "all"): 6,
}
TOTAL_TARGET_IMAGES = 52


def generate_dataset_stats(gt_path: str, out_dir: str):
    gt_rows = load_ground_truth(gt_path) if os.path.exists(gt_path) else []
    os.makedirs(out_dir, exist_ok=True)

    total_count = len(gt_rows)

    doctype_counts = defaultdict(int)
    subtype_counts = defaultdict(int)
    lang_counts = defaultdict(int)
    script_counts = defaultdict(int)
    hw_counts = defaultdict(int)
    quality_counts = defaultdict(int)

    for r in gt_rows:
        doctype_counts[r.doc_type] += 1
        subtype_counts[f"{r.doc_type}/{r.doc_subtype}"] += 1
        lang_counts[r.language] += 1
        script_counts[r.script] += 1
        hw_counts["handwritten" if r.handwritten else "printed"] += 1
        quality_counts[r.image_quality] += 1

    # Target completion calculations
    completion_pct = (total_count / TOTAL_TARGET_IMAGES * 100) if TOTAL_TARGET_IMAGES > 0 else 0.0

    # Save dataset_stats.csv
    csv_path = os.path.join(out_dir, "dataset_stats.csv")
    stats_rows = []
    for dt, cnt in doctype_counts.items():
        stats_rows.append({"category": "doc_type", "name": dt, "count": cnt, "percentage": f"{(cnt/total_count*100):.1f}%" if total_count > 0 else "0.0%"})
    for lang, cnt in lang_counts.items():
        stats_rows.append({"category": "language", "name": lang, "count": cnt, "percentage": f"{(cnt/total_count*100):.1f}%" if total_count > 0 else "0.0%"})
    for hw, cnt in hw_counts.items():
        stats_rows.append({"category": "handwriting", "name": hw, "count": cnt, "percentage": f"{(cnt/total_count*100):.1f}%" if total_count > 0 else "0.0%"})

    if stats_rows:
        with open(csv_path, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=stats_rows[0].keys())
            writer.writeheader()
            writer.writerows(stats_rows)

    # Imbalance Warnings
    warnings = []
    if lang_counts.get("punjabi", 0) < 3:
        warnings.append("Punjabi/Gurmukhi sample size is low (< 3). Multilingual Gurmukhi evaluation requires additional samples.")
    if lang_counts.get("hindi", 0) < 5:
        warnings.append("Hindi/Devanagari sample size is low (< 5).")
    if hw_counts.get("handwritten", 0) < 5:
        warnings.append("Handwritten prescription sample size is low (< 5).")

    # Generate dataset_stats.md
    md_path = os.path.join(out_dir, "dataset_stats.md")
    md_content = f"""# YAAD OCR Spike v0.4 — Dataset Statistics & Target Completion Report

## 1. Overall Target Completion Status
- **Current Annotated Image Count**: `{total_count}` / `{TOTAL_TARGET_IMAGES}`
- **Target Completion**: **{completion_pct:.1f}%**
- **Benchmark Readiness**: {"READY FOR REAL EXECUTION" if total_count >= 50 else "PENDING — Dataset Collection in Progress"}

---

## 2. Target vs. Current Distribution

| Category / Subtype | Target Count | Current Count | Completion |
| :--- | :--- | :--- | :--- |
| **Bills** (Household) | 12 | {doctype_counts.get('bill', 0)} | {(doctype_counts.get('bill', 0)/12*100):.1f}% |
| **Printed Prescriptions** | 8 | {subtype_counts.get('prescription/clinic', 0)} | {(subtype_counts.get('prescription/clinic', 0)/8*100):.1f}% |
| **Handwritten Prescriptions** | 8 | {subtype_counts.get('prescription/hospital', 0)} | {(subtype_counts.get('prescription/hospital', 0)/8*100):.1f}% |
| **Medicine Strips** | 10 | {doctype_counts.get('medicine_strip', 0)} | {(doctype_counts.get('medicine_strip', 0)/10*100):.1f}% |
| **IDs** (Synthetic/Public) | 8 | {doctype_counts.get('id', 0)} | {(doctype_counts.get('id', 0)/8*100):.1f}% |
| **Warranties / Invoices** | 6 | {doctype_counts.get('warranty', 0)} | {(doctype_counts.get('warranty', 0)/6*100):.1f}% |

---

## 3. Language & Script Breakdown
- **English / Latin**: {lang_counts.get('english', 0)} images ({lang_counts.get('english', 0)/(total_count or 1)*100:.1f}%)
- **Hindi / Devanagari**: {lang_counts.get('hindi', 0)} images ({lang_counts.get('hindi', 0)/(total_count or 1)*100:.1f}%)
- **Punjabi / Gurmukhi**: {lang_counts.get('punjabi', 0)} images ({lang_counts.get('punjabi', 0)/(total_count or 1)*100:.1f}%)

---

## 4. Dataset Imbalance Warnings
"""
    if warnings:
        for w in warnings:
            md_content += f"- ⚠️ **Warning**: {w}\n"
    else:
        md_content += "- ✓ No dataset imbalance warnings detected.\n"

    with open(md_path, "w", encoding="utf-8") as f:
        f.write(md_content)

    print(f"[Dataset Stats] Saved {csv_path} and {md_path}. Target completion: {completion_pct:.1f}%")


def main():
    parser = argparse.ArgumentParser(description="Generate dataset statistics report")
    parser.add_argument("--gt", default="ground_truth.csv", help="Path to ground truth CSV")
    parser.add_argument("--out_dir", default="outputs", help="Output directory")
    args = parser.parse_args()

    generate_dataset_stats(args.gt, args.out_dir)


if __name__ == "__main__":
    main()
