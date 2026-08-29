# YAAD OCR Spike v0.5 — Real Benchmark Dataset Collection Guide

This guide is for the person collecting the real **52-image benchmark dataset** for YAAD.

---

## 1. Benchmark Target Distribution (~52 Images Total)

| Category / Subtype | Directory Target Path | Target Count |
| :--- | :--- | :--- |
| **Bills** | `images/bills/` | **12** |
| **Printed Prescriptions** | `images/prescriptions/printed/` | **8** |
| **Handwritten Prescriptions** | `images/prescriptions/handwritten/` | **8** |
| **Medicine Strips** | `images/medicine_strips/` | **10** |
| **IDs** (Synthetic/Public) | `images/ids/` | **8** |
| **Warranties / Invoices** | `images/warranties/` | **6** |
| **Total** | | **52** |

---

## 2. Category Collection Guidelines

### 2.1 Bills (`images/bills/` — Target: 12)
- Collect variation across household services:
  - Electricity bills (e.g. BSES, TATA Power, UPPCL)
  - Water bills (e.g. Delhi Jal Board)
  - Broadband / Fiber bills (e.g. Airtel, JioFiber)
  - Mobile postpaid bills
- Photo Variations:
  - Include flat well-lit photos, slightly angled photos, mild blur, and natural glare examples.
  - Languages: English, Hindi, Punjabi, or mixed language bills.

### 2.2 Printed Prescriptions (`images/prescriptions/printed/` — Target: 8)
- Collect printed OPD slips, hospital discharge summaries, or clinic printouts.
- Keep all images local only. Never commit or upload real patient prescriptions.

### 2.3 Handwritten Prescriptions (`images/prescriptions/handwritten/` — Target: 8)
- Collect real handwritten doctor prescriptions where ethically and legally permissible.
- Redact patient identity details that are irrelevant to field evaluation.
- Keep images local and protected by `.gitignore`.

### 2.4 Medicine Strips (`images/medicine_strips/` — Target: 10)
- Collect foil medicine strips across different brands, fonts, foil surface reflectiveness, curved shapes, and orientations.

### 2.5 IDs (`images/ids/` — Target: 8)
- Use **synthetic sample IDs** or public sample documents (Aadhaar, PAN, DL, Vehicle RC).
- **CRITICAL**: Do NOT collect or photograph real personal identity documents of actual people unless authorized.

### 2.6 Warranties & Receipts (`images/warranties/` — Target: 6)
- Collect electronics invoices, retail cash receipts, and warranty cards.

---

## 3. Objective Image Quality Definitions

Image quality is an **input condition**, NOT an OCR output evaluation. Label `image_quality` according to these objective rules:

- **`GOOD`**: Document fills frame, sharp focus, even lighting, no significant glare or perspective skew.
- **`ACCEPTABLE`**: Fully readable by a human, but exhibits moderate glare, slight perspective tilt, or mild shadow.
- **`POOR`**: Noticeable motion blur, strong reflections/glare on foil, steep camera angle, or low light.

---

## 4. Language & Script Annotation Rules

- **`english` / `latin`**: Text is purely English written in Latin script.
- **`hindi` / `devanagari`**: Text is Hindi written in Devanagari script.
- **`punjabi` / `gurmukhi`**: Text is Punjabi written in Gurmukhi script.
- **`hinglish` / `latin`**: Hindi words written phonetically using Latin letters (e.g. *"Bijli Ka Bill"*).
- **`mixed` / `mixed`**: Document contains both English (Latin) and Hindi (Devanagari) or Punjabi (Gurmukhi) text.
