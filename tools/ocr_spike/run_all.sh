#!/usr/bin/env bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "======================================================="
echo "  YAAD OCR & Structured Extraction Spike (v0.3)"
echo "======================================================="

# 1. Run Unit Tests
echo "[Step 1/5] Running Harness Unit Tests..."
python3 -m unittest discover -s tests

# 2. Run Tesseract Baseline
echo ""
echo "[Step 2/5] Running Tesseract OCR Extraction (Raw & Enhanced)..."
python3 scripts/extract_tesseract.py --gt ground_truth.csv --img_dir images --out_dir outputs

# 3. Run Vision Model Extraction
echo ""
echo "[Step 3/5] Running Vision LLM Extraction..."
python3 scripts/extract_vision.py --gt ground_truth.csv --img_dir images --out_dir outputs

# 4. Score Extractions
echo ""
echo "[Step 4/5] Running Scoring Engine & Calibration..."
python3 scripts/score.py --gt ground_truth.csv --out_dir outputs

# 5. Generate Markdown Summary & CSV Reports
echo ""
echo "[Step 5/5] Generating Summary Report & Metrics..."
python3 scripts/report.py --out_dir outputs

echo ""
echo "======================================================="
echo "✓ Pipeline complete! Check outputs/summary.md and outputs/report.csv"
echo "======================================================="
