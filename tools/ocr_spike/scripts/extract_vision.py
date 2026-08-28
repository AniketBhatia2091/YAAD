#!/usr/bin/env python3
"""
Configurable Vision Model Extraction Script.
Supports multiple vision providers (Google, OpenAI, Anthropic, Generic REST).
Part of YAAD OCR & Structured Extraction Spike v0.3.
"""

import argparse
import json
import os
import sys
import time
from typing import Dict, Any, Optional

from common import ExtractionResult, load_ground_truth
from vision_providers import get_vision_provider, BaseVisionProvider


SYSTEM_PROMPT = """You are YAAD's high-precision document extraction engine for Indian life documents (bills, prescriptions, medicine strips, IDs, warranties).
Extract all visible fields from the image and return a strict JSON object matching this schema:

{
  "document_type": "bill|prescription|medicine_strip|id|warranty|unknown",
  "fields": {
    "title": "Document title",
    "amount": "Numeric amount string or null",
    "currency": "INR or currency code or null",
    "due_date": "YYYY-MM-DD or null",
    "expiry_date": "YYYY-MM-DD or null",
    "document_number": "Account/Policy/Invoice/ID number or null",
    "person": "Name of account holder / patient or null",
    "medicine": "Medicine name or null",
    "dosage": "Dosage instructions or null",
    "provider": "Company/Hospital/Issuer name or null",
    "policy_number": "Policy number or null",
    "warranty_end": "YYYY-MM-DD or null",
    "application_deadline": "YYYY-MM-DD or null"
  },
  "confidence": {
    "title": 0.95,
    "amount": 0.90,
    "due_date": 0.85,
    "document_number": 0.92,
    "person": 0.88,
    "medicine": 0.85,
    "dosage": 0.80,
    "provider": 0.90
  }
}

STRICT RULES:
1. NEVER INVENT or hallucinate values. Return null for fields not explicitly visible.
2. PRESERVE THE ORIGINAL SCRIPT (Hindi/Devanagari, Punjabi/Gurmukhi, English/Latin). Do not transliterate.
3. Use ISO format YYYY-MM-DD for date values where possible.
4. Return confidence values between 0.00 and 1.00 for each extracted field.
"""


def extract_vision_api(image_path: str, provider: Optional[BaseVisionProvider]) -> ExtractionResult:
    """Sends document image to configured VisionProvider."""
    if not provider:
        return ExtractionResult(
            filename=os.path.basename(image_path),
            method="vision",
            fields={},
            confidence={},
            latency_seconds=0.0,
            raw_text="",
            error="Vision API Credentials or Provider missing. Set `export VISION_API_KEY='your-key'`.",
        )

    if not os.path.exists(image_path):
        return ExtractionResult(
            filename=os.path.basename(image_path),
            method="vision",
            fields={},
            confidence={},
            latency_seconds=0.0,
            raw_text="",
            error=f"Image file not found: {image_path}",
        )

    start_time = time.time()
    try:
        parsed_json = provider.extract_structured(image_path, SYSTEM_PROMPT)
        latency = time.time() - start_time

        fields = parsed_json.get("fields", {})
        confidence = parsed_json.get("confidence", {})

        return ExtractionResult(
            filename=os.path.basename(image_path),
            method="vision",
            fields=fields,
            confidence=confidence,
            latency_seconds=latency,
            raw_text=json.dumps(parsed_json, ensure_ascii=False),
        )

    except Exception as e:
        latency = time.time() - start_time
        return ExtractionResult(
            filename=os.path.basename(image_path),
            method="vision",
            fields={},
            confidence={},
            latency_seconds=latency,
            raw_text="",
            error=f"Vision extraction failed: {str(e)}",
        )


def main():
    parser = argparse.ArgumentParser(description="Run Configurable Vision Model extraction on spike dataset")
    parser.add_argument("--gt", default="ground_truth.csv", help="Path to ground truth CSV")
    parser.add_argument("--img_dir", default="images", help="Directory containing images")
    parser.add_argument("--out_dir", default="outputs", help="Output directory")
    args = parser.parse_args()

    gt_rows = load_ground_truth(args.gt)
    provider, provider_type, model_name = get_vision_provider()
    
    print(f"[Vision Spike] Provider: {provider_type} | Model: {model_name or 'default'}")

    vision_out_dir = os.path.join(args.out_dir, "vision")
    os.makedirs(vision_out_dir, exist_ok=True)

    for row in gt_rows:
        img_path = os.path.join(args.img_dir, row.filename)
        safe_name = row.filename.replace("/", "_")

        res = extract_vision_api(img_path, provider)
        out_file = os.path.join(vision_out_dir, f"{safe_name}.json")

        out_data = {
            "filename": res.filename,
            "method": res.method,
            "provider": provider_type,
            "model": model_name,
            "latency_seconds": res.latency_seconds,
            "fields": res.fields,
            "confidence": res.confidence,
            "error": res.error,
            "raw_text": res.raw_text,
        }

        with open(out_file, "w", encoding="utf-8") as f:
            json.dump(out_data, f, indent=2, ensure_ascii=False)

        if res.error:
            print(f"Skipped {row.filename}: {res.error}")
        else:
            print(f"Processed: {row.filename} | Latency: {res.latency_seconds:.2f}s")

    print("[Vision Spike] Done.")


if __name__ == "__main__":
    main()
