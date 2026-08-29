# YAAD OCR & Structured Extraction Spike (v0.4)

A standalone evaluation harness to measure structured information extraction accuracy across real, messy Indian daily life documents (bills, prescriptions, medicine strips, IDs, warranties).

---

## 1. Directory Architecture

```
tools/ocr_spike/
├── README.md                          # Annotation guide, privacy rules & execution guide
├── setup.sh                           # Dependency installer & system binary check
├── run_all.sh                         # Master pipeline script with dataset validation
├── ground_truth_template.csv          # Robust annotated ground truth schema template
├── ground_truth.csv                   # Baseline ground truth index
├── images/                            # Test document image dataset (Local only)
│   ├── .gitignore                     # Prevents committing private PII image files
│   ├── bills/                         # Household electricity, water, broadband bills
│   ├── prescriptions/                 # Printed and handwritten prescriptions
│   │   ├── printed/
│   │   └── handwritten/
│   ├── medicine_strips/               # Foil medicine strips (curved/reflective)
│   ├── ids/                           # Synthetic / public sample IDs (Aadhaar, PAN)
│   └── warranties/                    # Product warranties & purchase receipts
├── outputs/                           # Extraction outputs & evaluation results
│   ├── .gitignore
│   ├── dataset_stats.csv, dataset_stats.md # Target completion & dataset distribution reports
│   ├── score_results.csv, failure_analysis.csv, report.csv, summary.md
├── scripts/
│   ├── common.py                      # Schema definition, strict field matchers, ISO date/amount normalizers
│   ├── validate_dataset.py            # Dataset validator checking schema, missing files & metadata
│   ├── dataset_stats.py               # Dataset target checker & distribution metrics
│   ├── vision_providers.py            # Multi-provider adapter (Google, OpenAI, Anthropic, REST)
│   ├── stage1_preprocessing.py        # Stage 1: Contrast, sharpness, brightness analysis
│   ├── stage2_ocr.py                  # Stage 2: Raw OCR recognition & character stats
│   ├── stage3_parsing.py              # Stage 3: Candidate entity extraction
│   ├── stage4_mapping.py              # Stage 4: Target schema field mapping
│   ├── stage5_hallucination.py        # Stage 5: Hallucination & missing-value evidence check
│   ├── extract_tesseract.py           # Tesseract baseline & image enhancement script
│   ├── extract_vision.py              # Configurable Vision API extraction script
│   ├── score.py                       # Scoring engine, calibration & stage failure taxonomy
│   └── report.py                      # CSV report & Markdown summary generator
└── tests/                             # Unit tests & synthetic test fixtures
    ├── fixtures/                      # Safe synthetic CSV fixtures (valid_gt.csv, invalid_meta_gt.csv)
    └── test_ocr_spike.py             # Unit test suite covering validator, matchers & stats
```

---

## 2. Human Annotation Guide & Rules

When adding ground-truth rows to `ground_truth.csv`, follow these strict rules:

### Explicit Field Representations
- **`<NOT_PRESENT>`**: Use when a field is not present anywhere on the document.
- **`<UNREADABLE>`**: Use when a field is physically visible on the document but damaged, smudged, or unreadable.
- **`<NOT_APPLICABLE>`**: Use when a field is structurally irrelevant to the document type (e.g. medicine name on an electricity bill).

### Script & Language Rules
- **Native Script Preservation**: Record text in its actual visible script (e.g. Devanagari `दिल्ली जल बोर्ड`, Gurmukhi `ਬਿਜਲੀ ਬਿਲ`). **Do not transliterate** Hindi or Punjabi into English during annotation.
- **Date Normalization**: Normalize all visible dates to ISO `YYYY-MM-DD`. Record original date representation (e.g. `"5 Sep 2026"`) in the `notes` column.
- **Amount Normalization**: Normalize monetary amounts to plain float strings (e.g. `1847.00`). Do not include currency symbols or commas.

---

## 3. Privacy & Security Protections (CRITICAL)

The OCR spike evaluation dataset may involve sensitive Indian documents containing:
- Aadhaar / PAN / Driver License numbers
- Medical prescription details & patient names
- Addresses, phone numbers, policy numbers, or banking details

### Strict Privacy Safeguards
1. **NEVER COMMIT REAL IMAGES**: The `images/` directory is ignored by `.gitignore`. Real document images must remain local only.
2. **NEVER COMMIT CREDENTIALS**: API keys must be loaded via environment variables (`VISION_API_KEY`, `VISION_PROVIDER`, `VISION_MODEL`). Never hardcode or save API keys to repository files.
3. **SAFE SYNTHETIC EXAMPLES**: README examples and unit tests use synthetic dummy data (`tests/fixtures/`).

---

## 4. Benchmark Target Distribution (~52 Images)

| Category / Subtype | Target Count |
| :--- | :--- |
| **Household Bills** | 12 |
| **Printed Prescriptions** | 8 |
| **Handwritten Prescriptions** | 8 |
| **Medicine Strips** | 10 |
| **IDs** (Synthetic/Public) | 8 |
| **Warranties / Invoices** | 6 |
| **Total Target** | **52** |

---

## 5. Execution Commands

### Validate Dataset & Metadata
```bash
python3 scripts/validate_dataset.py --gt ground_truth.csv --img_dir images
```

### Calculate Dataset Target Completion & Distribution Statistics
```bash
python3 scripts/dataset_stats.py --gt ground_truth.csv --out_dir outputs
```

### Run Full Benchmark Pipeline
```bash
./run_all.sh
```
