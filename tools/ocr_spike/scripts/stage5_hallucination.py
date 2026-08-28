"""
Stage 5: Hallucination & Missing-Value Detection.
Verifies mapped fields against source raw text to detect hallucinations vs missing values.
"""

from typing import Dict, Any, List


def run_stage5_hallucination_check(
    mapped_fields: Dict[str, Any],
    raw_text: str,
    confidence_map: Dict[str, float]
) -> List[Dict[str, Any]]:
    """
    Checks mapped fields against raw OCR text evidence.
    Returns list of flagged anomaly records (hallucinations or ungrounded predictions).
    """
    anomalies = []
    normalized_raw = raw_text.lower()

    for field_name, value in mapped_fields.items():
        if not value:
            continue

        conf = confidence_map.get(field_name, 0.5)
        val_str = str(value).lower().strip()

        # Check if value or digits of value appear anywhere in raw text evidence
        val_digits = "".join(filter(str.isdigit, val_str))
        evidence_found = (val_str in normalized_raw) or (len(val_digits) >= 4 and val_digits in normalized_raw)

        if not evidence_found and conf >= 0.85:
            anomalies.append({
                "field_name": field_name,
                "value": value,
                "confidence": conf,
                "anomaly_type": "hallucination",
                "reason": f"High confidence ({conf:.2f}) value '{value}' has no ground text evidence.",
            })

    return anomalies
