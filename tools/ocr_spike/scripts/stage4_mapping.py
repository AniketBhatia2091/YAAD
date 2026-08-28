"""
Stage 4: Field Schema Mapping.
Maps parsed candidates or Vision JSON into target YAAD schema fields.
"""

from typing import Dict, Any, Optional


TARGET_SCHEMA_KEYS = [
    "title",
    "amount",
    "currency",
    "due_date",
    "expiry_date",
    "document_number",
    "person",
    "medicine",
    "dosage",
    "provider",
    "policy_number",
    "warranty_end",
    "application_deadline",
]


def run_stage4_mapping(parsed_data: Dict[str, Any]) -> Dict[str, Optional[str]]:
    """Maps fields into standardized schema keys."""
    mapped: Dict[str, Optional[str]] = {k: None for k in TARGET_SCHEMA_KEYS}

    for key, val in parsed_data.items():
        clean_key = key.replace("expected_", "").strip()
        if clean_key in mapped:
            mapped[clean_key] = str(val).strip() if val is not None else None

    return mapped
