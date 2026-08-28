# YAAD OCR & Structured Extraction Spike (v0.3)

A standalone evaluation harness to measure structured information extraction accuracy across real, messy Indian daily life documents (bills, prescriptions, medicine strips, IDs, warranties).

---

## 1. Directory Structure

```
tools/ocr_spike/
├── README.md                          # Documentation & execution guide
├── setup.sh                           # Environment setup script
├── run_all.sh                         # Full benchmark execution pipeline
├── ground_truth_template.csv          # Annotated ground truth schema template
├── ground_truth.csv                   # Benchmark evaluation dataset index
├── images/                            # Test document image dataset
│   ├── .gitignore                     # Prevents committing private user PII/images
│   ├── bills/                         # Electricity, water, broadband bills
│   ├── prescriptions/                 # Printed and handwritten prescriptions
│   ├── medicine_strips/               # Foil medicine strips (curved/reflective)
│   ├── ids/                           # Synthetic / public sample IDs (Aadhaar, PAN)
│   └── warranties/                    # Product warranties & purchase receipts
├── outputs/                           # Extraction outputs & evaluation results
│   ├── .gitignore
│   ├── tesseract_raw/                 # Raw Tesseract OCR text dumps
│   ├── tesseract_enhanced/            # Image-preprocessed Tesseract OCR dumps
│   ├── vision/                        # Vision LLM structured JSON extractions
│   ├── score_results.csv              # Field-by-field evaluation breakdown
│   ├── failure_analysis.csv           # Failure taxonomy categorizations
│   ├── report.csv                     # Method x DocType & Method x Language matrices
│   └── summary.md                     # Executive summary report
├── scripts/
│   ├── common.py                      # Normalization, fuzzy matchers, GT reader
│   ├── extract_tesseract.py           # Tesseract baseline & image enhancement pipeline
│   ├── extract_vision.py              # Structured Vision API extraction script
│   ├── score.py                       # Scoring engine, calibration & failure taxonomy
│   └── report.py                      # CSV report & Markdown summary generator
└── tests/
    └── test_ocr_spike.py             # Unit tests for matching rules & schema validation
```

---

## 2. Privacy & Security Rules (CRITICAL)

The OCR spike evaluation dataset may involve sensitive documents.
- **NEVER COMMIT TO GIT**:
  - Real Aadhaar / PAN / Voter ID cards
  - Real prescriptions containing identifiable patient information or medical history
  - Real insurance policy numbers, home addresses, phone numbers, or private receipts
- The `images/` and `outputs/` directories contain `.gitignore` files to ensure image files and OCR output dumps remain local and are never pushed to remote repositories.
- Use only synthetic, public sample, or dummy test documents in committed examples.

---

## 3. Installation & Setup

### Environment Setup
Run the setup script:
```bash
./setup.sh
```

### Install Tesseract OCR Binary & Language Packs
- **macOS**:
  ```bash
  brew install tesseract tesseract-lang
  ```
- **Linux (Ubuntu/Debian)**:
  ```bash
  sudo apt-get install tesseract-ocr tesseract-ocr-hin tesseract-ocr-pan
  ```

---

## 4. API Credentials Configuration

Set your Vision API credentials via environment variables before running Vision extractions:
```bash
export VISION_API_KEY="your-gemini-or-vision-api-key"
export VISION_MODEL="gemini-2.5-flash"  # Optional model override
```

---

## 5. Execution Guide

Run the full evaluation pipeline end-to-end:
```bash
./run_all.sh
```

Or execute individual steps:

1. **Run Unit Tests**:
   ```bash
   python3 -m unittest discover -s tests
   ```

2. **Run Tesseract OCR Baseline**:
   ```bash
   python3 scripts/extract_tesseract.py --gt ground_truth.csv --img_dir images --out_dir outputs
   ```

3. **Run Structured Vision AI Extraction**:
   ```bash
   python3 scripts/extract_vision.py --gt ground_truth.csv --img_dir images --out_dir outputs
   ```

4. **Score Extractions & Analyze Calibration**:
   ```bash
   python3 scripts/score.py --gt ground_truth.csv --out_dir outputs
   ```

5. **Generate Summary Report**:
   ```bash
   python3 scripts/report.py --out_dir outputs
   ```

---

## 6. Scoring Methodology & Decision Thresholds

### Field Matching Rules (`scripts/common.py`)
- **Text**: Substring and token overlap after NFKD normalization. Preserves Hindi (Devanagari) and Punjabi (Gurmukhi) scripts without forced transliteration.
- **Numeric**: Normalizes `₹1,847.00`, `Rs. 1847/-`, `1847.0` $\rightarrow$ `1847.0`.
- **Date**: Normalizes `05/09/2026`, `5 Sep 2026`, `05-09-26` $\rightarrow$ ISO `2026-09-05`.

### Decision Thresholds
- **BUILD**: Printed bills / IDs ($\ge 90\%$ required-field accuracy).
- **LIMITED BUILD**: Printed prescriptions ($\ge 85\%$) with user confirmation UX.
- **DO NOT PROMISE**: Handwritten regional-language prescriptions (below reliable thresholds).
