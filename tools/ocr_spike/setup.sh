#!/usr/bin/env bash
set -e

echo "=== YAAD OCR & Structured Extraction Spike (v0.3) Setup ==="

# Set python path for user site packages if present
if [ -d "$HOME/Library/Python/3.9/lib/python/site-packages" ]; then
    export PYTHONPATH="$HOME/Library/Python/3.9/lib/python/site-packages:$PYTHONPATH"
fi

# Install Python requirements
echo "[1/2] Installing Python package dependencies..."
python3 -m pip install --quiet pillow requests pandas pytesseract || true

# Check Tesseract binary installation
echo "[2/2] Checking Tesseract OCR binary..."
if command -v tesseract &> /dev/null; then
    echo "✓ Tesseract binary found: $(which tesseract)"
    tesseract --version | head -n 1
    echo "Installed languages:"
    tesseract --list-langs
else
    echo "⚠ Tesseract binary NOT found on your system PATH."
    echo ""
    echo "To install Tesseract OCR with Indian language support:"
    echo "  - macOS:   brew install tesseract tesseract-lang"
    echo "  - Ubuntu:  sudo apt-get install tesseract-ocr tesseract-ocr-hin tesseract-ocr-pan"
    echo "  - Windows: Download installer from https://github.com/UB-Mannheim/tesseract/wiki"
fi

echo ""
echo "=== Setup completed ==="
