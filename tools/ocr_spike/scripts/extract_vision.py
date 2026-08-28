#!/usr/bin/env python3
"""
Structured Vision LLM Extraction Script.
Part of YAAD OCR & Structured Extraction Spike v0.3.
"""

import argparse
import json
import os
import sys
import time
from typing import Dict, Any, Optional

from common import ExtractionResult, load_ground_truth


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


def extract_vision_api(image_path: str, model_name: str = "gemini-2.5-flash") -> ExtractionResult:
    """
    Sends document image to Vision API and parses structured extraction response.
    Reads API credentials from environment variable `VISION_API_KEY` or `GEMINI_API_KEY`.
    """
    api_key = os.getenv("VISION_API_KEY") or os.getenv("GEMINI_API_KEY")
    if not api_key:
        return ExtractionResult(
            filename=os.path.basename(image_path),
            method="vision",
            fields={},
            confidence={},
            latency_seconds=0.0,
            raw_text="",
            error="API Key missing. Set environment variable `export VISION_API_KEY='your-key'`.",
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
        import base64
        import requests

        with open(image_path, "rb") as image_file:
            b64_image = base64.b64encode(image_file.read()).decode("utf-8")

        # Generic REST Vision API invocation endpoint
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent?key={api_key}"
        headers = {"Content-Type": "application/json"}
        payload = {
            "contents": [
                {
                    "parts": [
                        {"text": SYSTEM_PROMPT},
                        {
                            "inline_data": {
                                "mime_type": "image/jpeg",
                                "data": b64_image,
                            }
                        },
                    ]
                }
            ],
            "generationConfig": {"response_mime_type": "application/json"},
        }

        response = requests.post(url, headers=headers, json=payload, timeout=30)
        latency = time.time() - start_time

        if response.status_code != 200:
            return ExtractionResult(
                filename=os.path.basename(image_path),
                method="vision",
                fields={},
                confidence={},
                latency_seconds=latency,
                raw_text=response.text,
                error=f"Vision API HTTP {response.status_code}: {response.text[:200]}",
            )

        resp_json = response.json()
        raw_content = resp_json["candidates"][0]["content"]["parts"][0]["text"]
        parsed = json.loads(raw_content)

        fields = parsed.get("fields", {})
        confidence = parsed.get("confidence", {})

        return ExtractionResult(
            filename=os.path.basename(image_path),
            method="vision",
            fields=fields,
            confidence=confidence,
            latency_seconds=latency,
            raw_text=raw_content,
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
    parser = argparse.ArgumentParser(description="Run Vision Model extraction on spike dataset")
    parser.add_argument("--gt", default="ground_truth.csv", help="Path to ground truth CSV")
    parser.add_argument("--img_dir", default="images", help="Directory containing images")
    parser.add_argument("--out_dir", default="outputs", help="Output directory")
    parser.add_argument("--model", default="gemini-2.5-flash", help="Vision model identifier")
    args = parser.parse_args()

    gt_rows = load_ground_truth(args.gt)
    print(f"[Vision Spike] Running Vision API extraction ({args.model}) on {len(gt_rows)} images...")

    vision_out_dir = os.path.join(args.out_dir, "vision")
    os.makedirs(vision_out_dir, exist_ok=True)

    for row in gt_rows:
        img_path = os.path.join(args.img_dir, row.filename)
        safe_name = row.filename.replace("/", "_")

        res = extract_vision_api(img_path, model_name=args.model)
        out_file = os.path.join(vision_out_dir, f"{safe_name}.json")

        out_data = {
            "filename": res.filename,
            "method": res.method,
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
