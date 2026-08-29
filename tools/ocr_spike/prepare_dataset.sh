#!/usr/bin/env bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

if [ -d "$HOME/Library/Python/3.9/lib/python/site-packages" ]; then
    export PYTHONPATH="$HOME/Library/Python/3.9/lib/python/site-packages:$PYTHONPATH"
fi

echo "======================================================="
echo "  YAAD OCR Spike — Local Dataset Preparation Helper"
echo "======================================================="

# 1. Scan image directories for unannotated images
echo "[1/4] Scanning images/ directory for unannotated files..."
python3 -c "
import os, csv

gt_path = 'ground_truth.csv'
annotated = set()
if os.path.exists(gt_path):
    with open(gt_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for r in reader:
            if r.get('filename'):
                annotated.add(r['filename'].strip())

unannotated = []
for root, _, files in os.walk('images'):
    for file in files:
        if file.startswith('.') or file == '.gitkeep':
            continue
        rel_path = os.path.relpath(os.path.join(root, file), 'images')
        if rel_path not in annotated:
            unannotated.append(rel_path)

if unannotated:
    print(f'⚠️ Found {len(unannotated)} unannotated image(s) in images/:')
    for u in unannotated:
        print(f'  - {u}')
    print('\nPlease add corresponding rows in ground_truth.csv!')
else:
    print('✓ All image files in images/ have ground_truth.csv entries.')
"

# 2. Run Dataset Validation
echo ""
echo "[2/4] Validating ground_truth.csv schema and file integrity..."
python3 scripts/validate_dataset.py --gt ground_truth.csv --img_dir images --manifest dataset_manifest.json

# 3. Generate Dataset Statistics & Remaining Target Counts
echo ""
echo "[3/4] Generating dataset completion statistics..."
python3 scripts/dataset_stats.py --gt ground_truth.csv --out_dir outputs --manifest dataset_manifest.json

# 4. Display Summary & Remaining Target Checklist
echo ""
echo "[4/4] Summary Report Generated!"
cat outputs/dataset_stats.md | grep -E "Target Completion|Bills|Prescriptions|Medicine|IDs|Warranties" || true

echo ""
echo "======================================================="
echo "✓ Preparation complete! Check outputs/dataset_stats.md"
echo "======================================================="
