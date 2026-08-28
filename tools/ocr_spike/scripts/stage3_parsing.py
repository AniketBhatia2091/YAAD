"""
Stage 3: Structured Field Parsing.
Parses candidate entities (amounts, dates, numbers, tokens) from raw OCR text or Vision outputs.
"""

import re
from typing import Dict, Any, List


def run_stage3_parsing(raw_text: str) -> Dict[str, Any]:
    """Parses candidate entities from raw OCR text using pattern extraction."""
    parsed_fields: Dict[str, Any] = {}
    
    # Amount candidate
    amounts = re.findall(r"(?:₹|Rs\.?|INR)\s*([\d,]+(?:\.\d{2})?)", raw_text, re.IGNORECASE)
    if amounts:
        parsed_fields["amount"] = amounts[0].replace(",", "")

    # Date candidates
    dates = re.findall(r"\b(\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4}|\d{4}[-/.]\d{1,2}[-/.]\d{1,2})\b", raw_text)
    if dates:
        parsed_fields["due_date"] = dates[0]
        if len(dates) > 1:
            parsed_fields["expiry_date"] = dates[1]

    # Document number candidate
    doc_nums = re.findall(r"(?:Account|Policy|Invoice|Aadhaar|No\.?)\s*:?\s*([A-Z0-9\s-]{6,16})", raw_text, re.IGNORECASE)
    if doc_nums:
        parsed_fields["document_number"] = doc_nums[0].strip()

    return {
        "parsed_fields": parsed_fields,
        "candidate_count": len(parsed_fields),
    }
