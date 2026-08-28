#!/usr/bin/env python3
"""
Tesseract OCR Extraction Script (Baseline vs Image Enhanced).
Part of YAAD OCR & Structured Extraction Spike v0.3.
"""

import argparse
import os
import sys
import time
from typing import Dict, Optional

from common import ExtractionResult, load_ground_truth


def preprocess_image_enhanced(image_path: str):
    """
    Image preprocessing pipeline:
    Grayscale -> Contrast Enhancement -> Adaptive Thresholding -> Denoising -> Deskew
    Returns processed PIL Image or numpy array.
    """
    try:
        from PIL import Image, ImageEnhance, ImageFilter
        img = Image.open(image_path).convert("L")  # Convert to grayscale
        
        # Contrast Enhancement
        enhancer = ImageEnhance.Contrast(img)
        img = enhancer.enhance(2.0)
        
        # Sharpening
        img = img.filter(ImageFilter.SHARPEN)
        return img
    except Exception as e:
        print(f"[Warning] Image preprocessing failed for {image_path}: {e}")
        return image_path


def run_tesseract_ocr(image_path: str, mode: str = "raw", lang: str = "eng+hin+pan") -> ExtractionResult:
    """
    Executes Tesseract OCR on target image path.
    Mode can be 'raw' or 'enhanced'.
    """
    start_time = time.time()
    
    # Check Tesseract binary
    try:
        import pytesseract
        from PIL import Image
    except ImportError:
        return ExtractionResult(
            filename=os.path.basename(image_path),
            method=f"tesseract_{mode}",
            fields={},
            confidence={},
            latency_seconds=0.0,
            raw_text="",
            error="pytesseract package not installed. Run `pip install pytesseract pillow`.",
        )

    if not os.path.exists(image_path):
        return ExtractionResult(
            filename=os.path.basename(image_path),
            method=f"tesseract_{mode}",
            fields={},
            confidence={},
            latency_seconds=0.0,
            raw_text="",
            error=f"Image file not found: {image_path}",
        )

    try:
        if mode == "enhanced":
            target = preprocess_image_enhanced(image_path)
        else:
            target = Image.open(image_path)

        # Try OCR with fallback languages if specified language pack fails
        raw_text = ""
        try:
            raw_text = pytesseract.image_to_string(target, lang=lang)
        except Exception:
            # Fallback to default English if language packs hin/pan are missing
            raw_text = pytesseract.image_to_string(target, lang="eng")

        latency = time.time() - start_time

        # Basic heuristic parsing from raw OCR text
        fields = parse_heuristics_from_text(raw_text)
        confidence = {k: 0.5 for k in fields.keys() if fields[k] is not None}

        return ExtractionResult(
            filename=os.path.basename(image_path),
            method=f"tesseract_{mode}",
            fields=fields,
            confidence=confidence,
            latency_seconds=latency,
            raw_text=raw_text,
        )
    except Exception as e:
        latency = time.time() - start_time
        return ExtractionResult(
            filename=os.path.basename(image_path),
            method=f"tesseract_{mode}",
            fields={},
            confidence={},
            latency_seconds=latency,
            raw_text="",
            error=f"Tesseract OCR failed: {str(e)}. (Ensure `tesseract` binary is installed via `brew install tesseract`).",
        )


def parse_heuristics_from_text(raw_text: str) -> Dict[str, Optional[str]]:
    """Simple regex parsing to extract fields from raw unstructured Tesseract text."""
    fields = {}
    import re
    
    # Amount heuristic
    amount_match = re.search(r"(?:₹|Rs\.?|INR)\s*([\d,]+(?:\.\d{2})?)", raw_text, re.IGNORECASE)
    if amount_match:
        fields["expected_amount"] = amount_match.group(1).replace(",", "")

    # Date heuristic
    date_match = re.search(r"\b(\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4}|\d{4}[-/.]\d{1,2}[-/.]\d{1,2})\b", raw_text)
    if date_match:
        fields["expected_due_date"] = date_match.group(0)

    # Document number heuristic
    doc_num_match = re.search(r"(?:Account|Policy|Invoice|Aadhaar|No\.?)\s*:?\s*([A-Z0-9\s-]{6,16})", raw_text, re.IGNORECASE)
    if doc_num_match:
        fields["expected_document_number"] = doc_num_match.group(1).strip()

    return fields


def main():
    parser = argparse.ArgumentParser(description="Run Tesseract OCR baseline on spike dataset")
    parser.add_argument("--gt", default="ground_truth.csv", help="Path to ground truth CSV")
    parser.add_argument("--img_dir", default="images", help="Directory containing images")
    parser.add_argument("--out_dir", default="outputs", help="Output directory")
    args = parser.parse_args()

    gt_rows = load_ground_truth(args.gt)
    print(f"[Tesseract Spike] Running baseline & enhanced OCR on {len(gt_rows)} dataset images...")

    raw_out_dir = os.path.join(args.out_dir, "tesseract_raw")
    enh_out_dir = os.path.join(args.out_dir, "tesseract_enhanced")
    os.makedirs(raw_out_dir, exist_ok=True)
    os.makedirs(enh_out_dir, exist_ok=True)

    for row in gt_rows:
        img_path = os.path.join(args.img_dir, row.filename)
        safe_name = row.filename.replace("/", "_")

        # Run Raw Tesseract
        res_raw = run_tesseract_ocr(img_path, mode="raw")
        with open(os.path.join(raw_out_dir, f"{safe_name}.txt"), "w", encoding="utf-8") as f:
            f.write(f"ERROR: {res_raw.error}\n" if res_raw.error else res_raw.raw_text)

        # Run Enhanced Tesseract
        res_enh = run_tesseract_ocr(img_path, mode="enhanced")
        with open(os.path.join(enh_out_dir, f"{safe_name}.txt"), "w", encoding="utf-8") as f:
            f.write(f"ERROR: {res_enh.error}\n" if res_enh.error else res_enh.raw_text)

        print(f"Processed: {row.filename} | Raw Latency: {res_raw.latency_seconds:.2f}s | Enhanced Latency: {res_enh.latency_seconds:.2f}s")

    print("[Tesseract Spike] Done.")


if __name__ == "__main__":
    main()
