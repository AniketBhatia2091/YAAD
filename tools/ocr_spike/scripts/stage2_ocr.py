"""
Stage 2: OCR Recognition.
Executes raw character/word OCR recognition and returns raw text & character statistics.
"""

from typing import Dict, Any


def run_stage2_ocr(image_input, lang: str = "eng+hin+pan") -> Dict[str, Any]:
    """Runs raw OCR recognition on PIL image or file path."""
    try:
        import pytesseract
        from PIL import Image

        if isinstance(image_input, str):
            img = Image.open(image_input)
        else:
            img = image_input

        try:
            raw_text = pytesseract.image_to_string(img, lang=lang)
        except Exception:
            raw_text = pytesseract.image_to_string(img, lang="eng")

        lines = [line.strip() for line in raw_text.splitlines() if line.strip()]
        return {
            "success": True,
            "raw_text": raw_text,
            "char_count": len(raw_text),
            "line_count": len(lines),
            "error": None,
        }
    except Exception as e:
        return {
            "success": False,
            "raw_text": "",
            "char_count": 0,
            "line_count": 0,
            "error": f"OCR Recognition Stage 2 Failed: {str(e)}",
        }
