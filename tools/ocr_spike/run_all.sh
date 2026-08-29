#!/usr/bin/env bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

if [ -d "$HOME/Library/Python/3.9/lib/python/site-packages" ]; then
    export PYTHONPATH="$HOME/Library/Python/3.9/lib/python/site-packages:$PYTHONPATH"
fi

echo "======================================================="
echo "  YAAD OCR & Structured Extraction Spike (v0.5)"
echo "======================================================="

# 1. Run Privacy Preflight Guard Check
echo "[Step 1/7] Running Privacy Preflight Guard Check..."
./privacy_check.sh

# 2. Run Harness Unit Tests
echo ""
echo "[Step 2/7] Running Harness Unit Tests..."
python3 -m unittest discover -s tests

# 3. Run Dataset Validator
echo ""
echo "[Step 3/7] Running Dataset Validator..."
if ! python3 scripts/validate_dataset.py --gt ground_truth.csv --img_dir images --manifest dataset_manifest.json; then
    echo "❌ Dataset validation failed! Stopping pipeline."
    exit 1
fi

# 4. Run Dataset Statistics & Target Completion Check
echo ""
echo "[Step 4/7] Running Dataset Statistics & Target Completion Checker..."
python3 scripts/dataset_stats.py --gt ground_truth.csv --out_dir outputs --manifest dataset_manifest.json

# 5. Run Tesseract Baseline
echo ""
echo "[Step 5/7] Running Tesseract OCR Extraction (Raw & Enhanced)..."
python3 scripts/extract_tesseract.py --gt ground_truth.csv --img_dir images --out_dir outputs

# 6. Run Vision Model Extraction
echo ""
echo "[Step 6/7] Running Vision LLM Extraction..."
python3 scripts/extract_vision.py --gt ground_truth.csv --img_dir images --out_dir outputs

# 7. Score Extractions & Generate Reports
echo ""
echo "[Step 7/7] Running Scoring Engine & Report Generator..."
python3 scripts/score.py --gt ground_truth.csv --out_dir outputs
python3 scripts/report.py --out_dir outputs

echo ""
echo "======================================================="
echo "✓ Pipeline complete! Check outputs/summary.md and outputs/dataset_stats.md"
echo "======================================================="
