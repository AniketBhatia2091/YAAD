"""
Stage 1: Image Quality Analysis & Preprocessing.
Evaluates contrast, sharpness, brightness, and produces preprocessed PIL image.
"""

from typing import Dict, Any, Tuple


def analyze_image_quality(image_path: str) -> Dict[str, Any]:
    """Measures image quality metrics (contrast, brightness, sharpness)."""
    try:
        from PIL import Image, ImageStat
        img = Image.open(image_path).convert("L")
        stat = ImageStat.Stat(img)
        
        mean_brightness = stat.mean[0]
        std_contrast = stat.stddev[0]
        width, height = img.size

        # Heuristic quality categorization
        if std_contrast > 45 and 60 < mean_brightness < 200:
            quality = "good"
        elif std_contrast > 25 and 40 < mean_brightness < 220:
            quality = "acceptable"
        else:
            quality = "poor"

        return {
            "width": width,
            "height": height,
            "brightness": round(mean_brightness, 2),
            "contrast": round(std_contrast, 2),
            "quality_category": quality,
        }
    except Exception as e:
        return {
            "width": 0,
            "height": 0,
            "brightness": 0.0,
            "contrast": 0.0,
            "quality_category": "unknown",
            "error": str(e),
        }


def preprocess_image(image_path: str, mode: str = "enhanced"):
    """
    Applies image preprocessing pipeline:
    Grayscale -> Contrast Enhancement -> Sharpening
    """
    try:
        from PIL import Image, ImageEnhance, ImageFilter
        img = Image.open(image_path)
        if mode == "raw":
            return img

        # Stage 1 Enhanced Pipeline
        gray = img.convert("L")
        contrast = ImageEnhance.Contrast(gray).enhance(2.0)
        sharpened = contrast.filter(ImageFilter.SHARPEN)
        return sharpened
    except Exception:
        return image_path
