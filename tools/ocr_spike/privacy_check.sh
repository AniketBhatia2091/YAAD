#!/usr/bin/env bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/../.."

echo "======================================================="
echo "  YAAD OCR Spike — Privacy Preflight Guard Check"
echo "======================================================="

ERRORS=0

# 1. Check for tracked document image files
echo "[1/3] Checking for tracked document images in Git..."
TRACKED_IMAGES=$(git ls-files | grep -E '\.(jpg|jpeg|webp|pdf)$' | grep -v 'mipmap' | grep -v 'AppIcon' | grep -v 'LaunchImage' | grep -v 'favicon' || true)

if [ -n "$TRACKED_IMAGES" ]; then
    echo "❌ PRIVACY VIOLATION: Tracked document images found in Git repository:"
    echo "$TRACKED_IMAGES"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ No user document images tracked in Git."
fi

# 2. Check for tracked .env files or hardcoded API keys
echo ""
echo "[2/3] Checking for tracked .env files and hardcoded API keys..."
TRACKED_ENVS=$(git ls-files | grep -E '\.env$' || true)
if [ -n "$TRACKED_ENVS" ]; then
    echo "❌ PRIVACY VIOLATION: Tracked .env files found:"
    echo "$TRACKED_ENVS"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ No .env files tracked in Git."
fi

KEY_MATCHES=$(git grep -iE '(VISION_API_KEY|GEMINI_API_KEY|OPENAI_API_KEY)\s*=\s*["'\''\w]' -- ':!tools/ocr_spike/README.md' ':!tools/ocr_spike/DATASET_COLLECTION.md' ':!tools/ocr_spike/ANNOTATION_CHECKLIST.md' ':!tools/ocr_spike/scripts/extract_vision.py' ':!tools/ocr_spike/scripts/vision_providers.py' || true)
if [ -n "$KEY_MATCHES" ]; then
    echo "❌ PRIVACY VIOLATION: Hardcoded API keys detected:"
    echo "$KEY_MATCHES"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ No hardcoded API keys found in tracked source files."
fi

# 3. Check for tracked OCR output files containing PII
echo ""
echo "[3/3] Checking outputs/ tracking status..."
TRACKED_OUTPUTS=$(git ls-files | grep -E '^tools/ocr_spike/outputs/(score_results|failure_analysis|raw_ocr)' || true)
if [ -n "$TRACKED_OUTPUTS" ]; then
    echo "❌ PRIVACY VIOLATION: Tracked OCR extraction outputs found in Git:"
    echo "$TRACKED_OUTPUTS"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ Extraction outputs are properly excluded from Git by .gitignore."
fi

echo ""
echo "======================================================="
if [ $ERRORS -gt 0 ]; then
    echo "❌ Privacy check FAILED with $ERRORS error(s). Please unstage sensitive files!"
    exit 1
else
    echo "✓ Privacy check PASSED cleanly. Repository is safe."
    exit 0
fi
