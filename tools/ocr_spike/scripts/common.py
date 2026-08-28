import csv
import re
import unicodedata
from dataclasses import dataclass
from datetime import datetime
from typing import Dict, List, Optional


@dataclass
class GroundTruthRow:
    filename: str
    doc_type: str
    language: str
    script: str
    handwritten: bool
    image_quality: str
    expected_title: str
    expected_amount: Optional[str] = None
    expected_currency: Optional[str] = None
    expected_due_date: Optional[str] = None
    expected_expiry_date: Optional[str] = None
    expected_document_number: Optional[str] = None
    expected_person: Optional[str] = None
    expected_medicine: Optional[str] = None
    expected_dosage: Optional[str] = None
    expected_provider: Optional[str] = None
    expected_policy_number: Optional[str] = None
    expected_warranty_end: Optional[str] = None
    expected_application_deadline: Optional[str] = None
    notes: Optional[str] = None


@dataclass
class ExtractionResult:
    filename: str
    method: str  # 'tesseract_raw', 'tesseract_enhanced', 'vision'
    fields: Dict[str, Optional[str]]
    confidence: Dict[str, float]
    latency_seconds: float
    raw_text: str
    error: Optional[str] = None


def normalize_text(text: Optional[str]) -> str:
    """
    Normalizes text for comparison while preserving original script characters (Devanagari, Gurmukhi, etc.).
    Applies NFKD normalization, collapses whitespace, strips leading/trailing punctuation.
    """
    if not text:
        return ""
    
    # Normalize unicode
    normalized = unicodedata.normalize("NFKD", text)
    # Collapse multiple whitespaces/newlines
    normalized = re.sub(r"\s+", " ", normalized).strip()
    # Lowercase Latin text while preserving Devanagari/Gurmukhi
    normalized = normalized.lower()
    return normalized


def normalize_numeric(value: Optional[str]) -> Optional[float]:
    """
    Parses currency/amount representations like '₹1,847.00', 'Rs. 1847/-', '1847.50' into a float.
    """
    if not value:
        return None
    
    # Remove currency symbols, commas, trailing slashes (keep decimal dot)
    clean = re.sub(r"[₹\$\,Rs\s\/\-]", "", str(value), flags=re.IGNORECASE)
    # Match digits and optional decimal
    match = re.search(r"\d+(\.\d+)?", clean)
    if match:
        try:
            return float(match.group(0))
        except ValueError:
            return None
    return None


def normalize_date(date_str: Optional[str]) -> Optional[str]:
    """
    Parses date representations ('05/09/2026', '2026-09-05', '5 Sep 2026', '05-09-26')
    and returns ISO formatted date 'YYYY-MM-DD'.
    """
    if not date_str:
        return None
    
    clean_str = date_str.strip()
    # If already ISO format YYYY-MM-DD
    if re.match(r"^\d{4}-\d{2}-\d{2}$", clean_str):
        return clean_str

    formats = [
        "%d/%m/%Y",
        "%d-%m-%Y",
        "%d/%m/%y",
        "%d-%m-%y",
        "%Y/%m/%d",
        "%d %b %Y",
        "%d %B %Y",
        "%b %d, %Y",
    ]

    for fmt in formats:
        try:
            dt = datetime.strptime(clean_str, fmt)
            return dt.strftime("%Y-%m-%d")
        except ValueError:
            continue
            
    # Try extract digits
    match = re.search(r"(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})", clean_str)
    if match:
        y, m, d = match.groups()
        return f"{int(y):04d}-{int(m):02d}-{int(d):02d}"
        
    return None


def match_text(expected: Optional[str], actual: Optional[str]) -> bool:
    """Fuzzy text match checking normalized substring / token overlap."""
    if not expected and not actual:
        return True
    if not expected or not actual:
        return False
    
    exp_norm = normalize_text(expected)
    act_norm = normalize_text(actual)
    
    if exp_norm == act_norm:
        return True
    
    # Substring overlap check
    if exp_norm in act_norm or act_norm in exp_norm:
        return True
        
    return False


def match_numeric(expected: Optional[str], actual: Optional[str]) -> bool:
    """Matches numeric amounts accurately."""
    exp_num = normalize_numeric(expected)
    act_num = normalize_numeric(actual)
    
    if exp_num is None and act_num is None:
        return True
    if exp_num is None or act_num is None:
        return False
        
    return abs(exp_num - act_num) < 0.01


def match_date(expected: Optional[str], actual: Optional[str]) -> bool:
    """Matches date fields by comparing normalized ISO representations."""
    exp_date = normalize_date(expected)
    act_date = normalize_date(actual)
    
    if exp_date is None and act_date is None:
        return True
    if exp_date is None or act_date is None:
        return False
        
    return exp_date == act_date


def load_ground_truth(csv_path: str) -> List[GroundTruthRow]:
    """Reads ground truth CSV file into GroundTruthRow instances."""
    rows = []
    with open(csv_path, mode="r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for r in reader:
            rows.append(
                GroundTruthRow(
                    filename=(r.get("filename") or "").strip(),
                    doc_type=(r.get("doc_type") or "").strip().lower(),
                    language=(r.get("language") or "").strip().lower(),
                    script=(r.get("script") or "").strip().lower(),
                    handwritten=(r.get("handwritten") or "false").strip().lower() == "true",
                    image_quality=(r.get("image_quality") or "good").strip().lower(),
                    expected_title=(r.get("expected_title") or "").strip(),
                    expected_amount=(r.get("expected_amount") or "").strip() or None,
                    expected_currency=(r.get("expected_currency") or "").strip() or None,
                    expected_due_date=(r.get("expected_due_date") or "").strip() or None,
                    expected_expiry_date=(r.get("expected_expiry_date") or "").strip() or None,
                    expected_document_number=(r.get("expected_document_number") or "").strip() or None,
                    expected_person=(r.get("expected_person") or "").strip() or None,
                    expected_medicine=(r.get("expected_medicine") or "").strip() or None,
                    expected_dosage=(r.get("expected_dosage") or "").strip() or None,
                    expected_provider=(r.get("expected_provider") or "").strip() or None,
                    expected_policy_number=(r.get("expected_policy_number") or "").strip() or None,
                    expected_warranty_end=(r.get("expected_warranty_end") or "").strip() or None,
                    expected_application_deadline=(r.get("expected_application_deadline") or "").strip() or None,
                    notes=(r.get("notes") or "").strip() or None,
                )
            )
    return rows
