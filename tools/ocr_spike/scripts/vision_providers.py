import base64
import json
import os
import time
from typing import Dict, Any, Optional, Tuple


class BaseVisionProvider:
    """Base class for configurable vision model providers."""
    
    def extract_structured(self, image_path: str, system_prompt: str) -> Dict[str, Any]:
        raise NotImplementedError


class GoogleVisionProvider(BaseVisionProvider):
    def __init__(self, api_key: str, model: str = "gemini-2.5-flash"):
        self.api_key = api_key
        self.model = model

    def extract_structured(self, image_path: str, system_prompt: str) -> Dict[str, Any]:
        import requests
        with open(image_path, "rb") as f:
            b64_img = base64.b64encode(f.read()).decode("utf-8")

        url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.model}:generateContent?key={self.api_key}"
        headers = {"Content-Type": "application/json"}
        payload = {
            "contents": [
                {
                    "parts": [
                        {"text": system_prompt},
                        {"inline_data": {"mime_type": "image/jpeg", "data": b64_img}},
                    ]
                }
            ],
            "generationConfig": {"response_mime_type": "application/json"},
        }
        resp = requests.post(url, headers=headers, json=payload, timeout=30)
        resp.raise_for_status()
        data = resp.json()
        raw_text = data["candidates"][0]["content"]["parts"][0]["text"]
        return json.loads(raw_text)


class OpenAIVisionProvider(BaseVisionProvider):
    def __init__(self, api_key: str, model: str = "gpt-4o-mini"):
        self.api_key = api_key
        self.model = model

    def extract_structured(self, image_path: str, system_prompt: str) -> Dict[str, Any]:
        import requests
        with open(image_path, "rb") as f:
            b64_img = base64.b64encode(f.read()).decode("utf-8")

        url = "https://api.openai.com/v1/chat/completions"
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.api_key}",
        }
        payload = {
            "model": self.model,
            "response_format": {"type": "json_object"},
            "messages": [
                {"role": "system", "content": system_prompt},
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "Extract structured information from this document."},
                        {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{b64_img}"}},
                    ],
                },
            ],
        }
        resp = requests.post(url, headers=headers, json=payload, timeout=30)
        resp.raise_for_status()
        data = resp.json()
        raw_text = data["choices"][0]["message"]["content"]
        return json.loads(raw_text)


class AnthropicVisionProvider(BaseVisionProvider):
    def __init__(self, api_key: str, model: str = "claude-3-5-sonnet-20241022"):
        self.api_key = api_key
        self.model = model

    def extract_structured(self, image_path: str, system_prompt: str) -> Dict[str, Any]:
        import requests
        with open(image_path, "rb") as f:
            b64_img = base64.b64encode(f.read()).decode("utf-8")

        url = "https://api.anthropic.com/v1/messages"
        headers = {
            "Content-Type": "application/json",
            "x-api-key": self.api_key,
            "anthropic-version": "2023-06-01",
        }
        payload = {
            "model": self.model,
            "max_tokens": 1024,
            "system": system_prompt,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": b64_img,
                            },
                        },
                        {"type": "text", "text": "Extract structured data as JSON."},
                    ],
                }
            ],
        }
        resp = requests.post(url, headers=headers, json=payload, timeout=30)
        resp.raise_for_status()
        data = resp.json()
        raw_text = data["content"][0]["text"]
        return json.loads(raw_text)


class GenericRestVisionProvider(BaseVisionProvider):
    def __init__(self, api_key: str, endpoint: str, model: Optional[str] = None):
        self.api_key = api_key
        self.endpoint = endpoint
        self.model = model

    def extract_structured(self, image_path: str, system_prompt: str) -> Dict[str, Any]:
        import requests
        with open(image_path, "rb") as f:
            b64_img = base64.b64encode(f.read()).decode("utf-8")

        headers = {"Authorization": f"Bearer {self.api_key}", "Content-Type": "application/json"}
        payload = {"image_base64": b64_img, "prompt": system_prompt}
        if self.model:
            payload["model"] = self.model

        resp = requests.post(self.endpoint, headers=headers, json=payload, timeout=30)
        resp.raise_for_status()
        return resp.json()


def get_vision_provider() -> Tuple[Optional[BaseVisionProvider], Optional[str], Optional[str]]:
    """
    Factory function instantiating configured VisionProvider based on environment variables.
    """
    provider_type = (os.getenv("VISION_PROVIDER") or "google").lower()
    api_key = os.getenv("VISION_API_KEY") or os.getenv("GEMINI_API_KEY") or os.getenv("OPENAI_API_KEY") or os.getenv("ANTHROPIC_API_KEY")
    model = os.getenv("VISION_MODEL")

    if not api_key:
        return None, provider_type, model

    if provider_type == "google":
        model_name = model or "gemini-2.5-flash"
        return GoogleVisionProvider(api_key, model=model_name), provider_type, model_name
    elif provider_type == "openai":
        model_name = model or "gpt-4o-mini"
        return OpenAIVisionProvider(api_key, model=model_name), provider_type, model_name
    elif provider_type == "anthropic":
        model_name = model or "claude-3-5-sonnet-20241022"
        return AnthropicVisionProvider(api_key, model=model_name), provider_type, model_name
    elif provider_type == "generic_rest":
        endpoint = os.getenv("VISION_API_ENDPOINT", "")
        return GenericRestVisionProvider(api_key, endpoint=endpoint, model=model), provider_type, model
    else:
        return None, provider_type, model
