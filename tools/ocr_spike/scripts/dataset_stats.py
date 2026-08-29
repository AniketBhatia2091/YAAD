#!/usr/bin/env python3
"""
Dataset Statistics & Target Completion Checker Tool.
Generates dataset_stats.csv and dataset_stats.md.
Part of YAAD OCR Spike v0.5.
"""

import argparse
import csv
import json
import os
import sys
from collections import defaultdict
from typing import Dict, List, Any

from common import load_ground_truth


def load_manifest_targets(manifest_path: str) -> Dict[str, int]:
    if not os.path.exists(manifest_path):
        return {
            "bill": 12,
            "prescription_printed": 8,
            "prescription_handwritten": 8,
            "medicine_strip": 10,
            "id": 8,
            "warranty": 6,
        }
    with open(manifest_path, "r", encoding="utf-8") as f:
        data = json.load(f)
        cats = data.get("target_distribution", {}).get("categories", {})
        return {
            "bill": cats.get("bill", {}).get("target", 12),
            "prescription_printed": cats.get("prescription_printed", {}).get("target", 8),
            "prescription_handwritten": cats.get("prescription_handwritten", {}).get("target", 8),
            "medicine_strip": cats.get("medicine_strip", {}).get("target", 10),
            "id": cats.get("id", {}).get("target", 8),
            "warranty": cats.get("warranty", {}).get("target", 6),
        }


def generate_dataset_stats(gt_path: str, out_dir: str, manifest_path: str = "dataset_manifest.json"):
    gt_rows = load_ground_truth(gt_path) if os.path.exists(gt_path) else []
    os.makedirs(out_dir, exist_ok=True)
    targets = load_manifest_targets(manifest_path)
    total_target_images = sum(targets.values())

    total_count = len(gt_rows)

    doctype_counts = defaultdict(int)
    cat_counts = defaultdict(int)
    lang_counts = defaultdict(int)
    script_counts = defaultdict(int)
    hw_counts = defaultdict(int)
    quality_counts = defaultdict(int)

    for r in gt_rows:
        doctype_counts[r.doc_type] += 1
        lang_counts[r.language] += 1
        script_counts[r.script] += 1
        is_hw = r.handwritten
        hw_counts["handwritten" if is_hw else "printed"] += 1
        quality_counts[r.image_quality] += 1

        if r.doc_type == "prescription":
            cat_key = "prescription_handwritten" if is_hw else "prescription_printed"
        else:
            cat_key = r.doc_type
        cat_counts[cat_key] += 1

    completion_pct = (total_count / total_target_images * 100) if total_target_images > 0 else 0.0

    # Save dataset_stats.csv
    csv_path = os.path.join(out_dir, "dataset_stats.csv")
    stats_rows = []
    for cat_key, target_num in targets.items():
        curr_num = cat_counts[cat_key]
        rem_num = max(0, target_num - curr_num)
        stats_rows.append({
            "category": cat_key,
            "target": target_num,
            "current": curr_num,
            "remaining": rem_num,
            "completion_pct": f"{(curr_num/target_num*100):.1f}%" if target_num > 0 else "0.0%",
        })

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
    if cat_counts.get("prescription_handwritten", 0) < 8:
        warnings.append(f"Handwritten prescription sample size ({cat_counts.get('prescription_handwritten', 0)}) is below target (8).")
    if quality_counts.get("poor", 0) == 0:
        warnings.append("Poor-quality/challenging images are currently unrepresented.")

    # Generate dataset_stats.md
    md_path = os.path.join(out_dir, "dataset_stats.md")
    md_content = f"""# YAAD OCR Spike v0.5 — Dataset Statistics & Target Completion Report

## 1. Overall Target Completion Status
- **Current Annotated Image Count**: `{total_count}` / `{total_target_images}`
- **Target Completion**: **{completion_pct:.1f}%**
- **Benchmark Readiness**: {"READY FOR REAL EXECUTION" if total_count >= 50 else "INSUFFICIENT DATA (PENDING — Dataset Collection in Progress)"}

---

## 2. Target vs. Current Distribution (Category Breakdown)

| Category | Target | Current | Remaining | Completion |
| :--- | :--- | :--- | :--- | :--- |
| **Bills** (Household) | {targets.get('bill', 12)} | {cat_counts.get('bill', 0)} | {max(0, targets.get('bill', 12) - cat_counts.get('bill', 0))} | {(cat_counts.get('bill', 0)/targets.get('bill', 12)*100):.1f}% |
| **Printed Prescriptions** | {targets.get('prescription_printed', 8)} | {cat_counts.get('prescription_printed', 0)} | {max(0, targets.get('prescription_printed', 8) - cat_counts.get('prescription_printed', 0))} | {(cat_counts.get('prescription_printed', 0)/targets.get('prescription_printed', 8)*100):.1f}% |
| **Handwritten Prescriptions** | {targets.get('prescription_handwritten', 8)} | {cat_counts.get('prescription_handwritten', 0)} | {max(0, targets.get('prescription_handwritten', 8) - cat_counts.get('prescription_handwritten', 0))} | {(cat_counts.get('prescription_handwritten', 0)/targets.get('prescription_handwritten', 8)*100):.1f}% |
| **Medicine Strips** | {targets.get('medicine_strip', 10)} | {cat_counts.get('medicine_strip', 0)} | {max(0, targets.get('medicine_strip', 10) - cat_counts.get('medicine_strip', 0))} | {(cat_counts.get('medicine_strip', 0)/targets.get('medicine_strip', 10)*100):.1f}% |
| **IDs** (Synthetic/Public) | {targets.get('id', 8)} | {cat_counts.get('id', 0)} | {max(0, targets.get('id', 8) - cat_counts.get('id', 0))} | {(cat_counts.get('id', 0)/targets.get('id', 8)*100):.1f}% |
| **Warranties / Invoices** | {targets.get('warranty', 6)} | {cat_counts.get('warranty', 6)} | {max(0, targets.get('warranty', 6) - cat_counts.get('warranty', 6))} | {(cat_counts.get('warranty', 0)/targets.get('warranty', 6)*100):.1f}% |

---

## 3. Language & Script Breakdown
- **English / Latin**: {lang_counts.get('english', 0)} images ({lang_counts.get('english', 0)/(total_count or 1)*100:.1f}%)
- **Hindi / Devanagari**: {lang_counts.get('hindi', 0)} images ({lang_counts.get('hindi', 0)/(total_count or 1)*100:.1f}%)
- **Punjabi / Gurmukhi**: {lang_counts.get('punjabi', 0)} images ({lang_counts.get('punjabi', 0)/(total_count or 1)*100:.1f}%)

---

## 4. Dataset Imbalance Warnings (Input Condition Checks)
"""
    if warnings:
        for w in warnings:
            md_content += f"- ⚠️ **Dataset Imbalance Warning**: {w}\n"
    else:
        md_content += "- ✓ No dataset imbalance warnings detected.\n"

    with open(md_path, "w", encoding="utf-8") as f:
        f.write(md_content)

    print(f"[Dataset Stats] Saved {csv_path} and {md_path}. Target completion: {completion_pct:.1f}% ({total_count}/{total_target_images})")


def main():
    parser = argparse.ArgumentParser(description="Generate dataset statistics report")
    parser.add_argument("--gt", default="ground_truth.csv", help="Path to ground truth CSV")
    parser.add_argument("--out_dir", default="outputs", help="Output directory")
    parser.add_argument("--manifest", default="dataset_manifest.json", help="Path to dataset_manifest.json")
    args = parser.parse_args()

    generate_dataset_stats(args.gt, args.out_dir, args.manifest)


if __name__ == "__main__":
    main()
