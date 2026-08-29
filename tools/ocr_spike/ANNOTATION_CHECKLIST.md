# YAAD OCR Spike v0.5 — Human Ground-Truth Annotation Checklist

Follow this checklist for every image added to `ground_truth.csv`.

---

## Step-by-Step Annotation Process

### 1. Unique Dataset Identification
- Assign a unique, stable `sample_id` (e.g. `BILL_001`, `RX_PRINTED_001`, `RX_HAND_001`, `MED_001`, `ID_001`, `WARRANTY_001`).
- Verify `sample_id` and `filename` are unique across the entire CSV.

### 2. Document Metadata
- `doc_type`: `bill`, `prescription`, `medicine_strip`, `id`, `warranty`
- `doc_subtype`: `electricity`, `water`, `broadband`, `mobile`, `clinic`, `hospital`, `manufacturer_strip`, `aadhaar`, `pan`, `driving_license`, `vehicle_rc`, `receipt`, `card`
- `language`: `english`, `hindi`, `punjabi`, `hinglish`, `mixed`
- `script`: `latin`, `devanagari`, `gurmukhi`, `mixed`
- `handwritten`: `true` or `false`
- `image_quality`: `good`, `acceptable`, `poor`
- `source_type`: `camera_photo`, `gallery_import`, `scanned_pdf`, `synthetic_fixture`

### 3. Field Ground-Truth Values
Inspect the original image directly and fill each expected field:

- **Field is visible & legible**: Record the exact visible value.
  - Native Script Rule: Record Hindi/Punjabi text in native script (`दिल्ली जल बोर्ड`, `ਬਿਜਲੀ ਬਿਲ`). Do not translate into English.
  - Date Normalization: Standardize dates to ISO `YYYY-MM-DD`.
  - Amount Normalization: Standardize amounts to plain float string (`1847.00`).
- **Field is absent on document**: Set to **`<NOT_PRESENT>`**.
- **Field is physically present but unreadable**: Set to **`<UNREADABLE>`**.
- **Field is structurally irrelevant**: Set to **`<NOT_APPLICABLE>`**.

### 4. Verification
Run dataset validation after annotating:
```bash
./tools/ocr_spike/prepare_dataset.sh
```
