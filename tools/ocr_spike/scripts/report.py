#!/usr/bin/env python3
"""
Report Generator for YAAD OCR & Structured Extraction Spike v0.4.
Outputs `outputs/report.csv` and `outputs/summary.md`.
"""

import argparse
import csv
import os
import sys
from collections import defaultdict
from typing import Dict, List


def generate_reports(out_dir: str):
    score_path = os.path.join(out_dir, "score_results.csv")
    report_csv_path = os.path.join(out_dir, "report.csv")
    summary_md_path = os.path.join(out_dir, "summary.md")

    score_records = []
    if os.path.exists(score_path):
        with open(score_path, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            score_records = list(reader)

    # Aggregations
    method_doctype = defaultdict(lambda: {"correct": 0, "total": 0})
    method_lang = defaultdict(lambda: {"correct": 0, "total": 0})
    method_hw = defaultdict(lambda: {"correct": 0, "total": 0})

    for r in score_records:
        m = r["method"]
        is_corr = r["is_correct"].lower() == "true"

        dt_key = (m, r["doc_type"])
        method_doctype[dt_key]["total"] += 1
        if is_corr:
            method_doctype[dt_key]["correct"] += 1

        lang_key = (m, r["language"])
        method_lang[lang_key]["total"] += 1
        if is_corr:
            method_lang[lang_key]["correct"] += 1

        hw_key = (m, "handwritten" if r["handwritten"].lower() == "true" else "printed")
        method_hw[hw_key]["total"] += 1
        if is_corr:
            method_hw[hw_key]["correct"] += 1

    report_rows = []
    for (m, dt), counts in method_doctype.items():
        acc = (counts["correct"] / counts["total"] * 100) if counts["total"] > 0 else "N/A"
        report_rows.append({
            "method": m,
            "category_type": "doc_type",
            "category_value": dt,
            "evaluated": counts["total"],
            "correct": counts["correct"],
            "accuracy_pct": f"{acc:.2f}" if isinstance(acc, float) else "N/A",
        })

    if report_rows:
        with open(report_csv_path, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=report_rows[0].keys())
            writer.writeheader()
            writer.writerows(report_rows)

    # Has real evaluation run?
    has_real_runs = len(score_records) > 0 and any(r["method"] == "vision" for r in score_records)

    summary_content = f"""# YAAD OCR & Structured Extraction Spike (v0.4) — Summary Report

> **BENCHMARK EXECUTION STATUS**: {"BENCHMARK EXECUTED" if has_real_runs else "PENDING — Dataset collection in progress or Vision API key unconfigured"}

---

## 1. Quantitative Benchmark Results

### Method × Document Type Accuracy
| Method | Document Type | Evaluated | Correct | Accuracy (%) |
| :--- | :--- | :--- | :--- | :--- |
"""
    if not score_records:
        summary_content += "| `tesseract_raw` | `all` | 0 | 0 | **PENDING** |\n"
        summary_content += "| `vision` | `all` | 0 | 0 | **PENDING** |\n"
    else:
        for (m, dt), counts in method_doctype.items():
            acc_str = f"{(counts['correct'] / counts['total'] * 100):.1f}%" if counts["total"] > 0 else "N/A"
            summary_content += f"| `{m}` | `{dt}` | {counts['total']} | {counts['correct']} | **{acc_str}** |\n"

    summary_content += """
---

## 2. Benchmark Recommendations

- **Dataset Status**: Real benchmark images must remain local and uncommitted for privacy compliance.
- **Production Architecture Decision**: **PENDING** (Production V1 decision will be made after local benchmark image execution).
"""

    with open(summary_md_path, "w", encoding="utf-8") as f:
        f.write(summary_content)

    print(f"[Report Generator] Saved {report_csv_path} and {summary_md_path}.")


def main():
    parser = argparse.ArgumentParser(description="Generate OCR spike report and executive summary")
    parser.add_argument("--out_dir", default="outputs", help="Output directory")
    args = parser.parse_args()

    generate_reports(args.out_dir)


if __name__ == "__main__":
    main()
