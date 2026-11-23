"""
Generic OpenAI-Compatible Provider Adapter for PeTTa Python LLM Bridge.
Communicates via standard HTTP REST chat-completions protocol using requests.
Serves as base class for OpenAI and DeepSeek adapters, and standalone for
OpenRouter, Together AI, Groq, Ollama, vLLM, and LocalAI endpoints.
"""

import json
from typing import Dict, Any, Optional
import requests

from python_bridge.providers.base import BaseLLMProvider
from python_bridge.config import LLMConfig

class GenericOpenAIProvider(BaseLLMProvider):
    """
    Adapter for any OpenAI-compatible /v1/chat/completions REST endpoint.
    """

    def __init__(
        self,
        config: LLMConfig,
        provider_name: str = "generic_openai",
        api_key: Optional[str] = None,
        base_url: Optional[str] = None,
        model_name: Optional[str] = None
    ):
        model = model_name or config.generic_model
        super().__init__(
            provider_name=provider_name,
            model_name=model,
            timeout=config.llm_timeout
        )
        self.config = config
        self.api_key = api_key if api_key is not None else config.generic_api_key
        raw_url = base_url if base_url is not None else config.generic_base_url
        self.endpoint_url = self._normalize_endpoint(raw_url)
        self._init_error: Optional[str] = None

        if not self.endpoint_url:
            self._init_error = f"Missing required base URL for provider '{self.provider_name}'."
        elif not self.api_key and "localhost" not in self.endpoint_url and "127.0.0.1" not in self.endpoint_url:
            self._init_error = f"API key is missing or empty for provider '{self.provider_name}'."

    @staticmethod
    def _normalize_endpoint(url: Optional[str]) -> str:
        """
        Normalizes base URL to guarantee standard /chat/completions target.
        Handles URLs with or without trailing slash and URLs that already include /chat/completions.
        """
        if not url or not url.strip():
            return ""
        clean = url.strip()
        while clean.endswith("/"):
            clean = clean[:-1]
        if clean.endswith("/chat/completions"):
            return clean
        return f"{clean}/chat/completions"

    def query(self, prompt: str) -> Dict[str, Any]:
        """
        Executes chat completion request over HTTP POST.
        """
        if self._init_error:
            return self.make_error_response(
                error_type="AuthenticationError" if "API key" in self._init_error else "ConfigurationError",
                message=self._init_error
            )

        if not prompt or not prompt.strip():
            return self.make_error_response(
                error_type="InvalidPromptError",
                message="Prompt cannot be empty."
            )

        headers = {
            "Content-Type": "application/json"
        }
        if self.api_key:
            headers["Authorization"] = f"Bearer {self.api_key}"

        payload = {
            "model": self.model_name,
            "messages": [
                {"role": "user", "content": prompt}
            ],
            "temperature": 0.7
        }

        try:
            resp = requests.post(
                self.endpoint_url,
                headers=headers,
                json=payload,
                timeout=self.timeout
            )
        except requests.exceptions.Timeout:
            return self.make_error_response(
                error_type="TimeoutError",
                message=f"Request to {self.provider_name} timed out after {self.timeout}s."
            )
        except requests.exceptions.ConnectionError as exc:
            return self.make_error_response(
                error_type="NetworkError",
                message=f"Connection error reaching {self.provider_name} endpoint: {str(exc)}"
            )
        except requests.exceptions.RequestException as exc:
            return self.make_error_response(
                error_type="NetworkError",
                message=f"Network request failure: {str(exc)}"
            )

        # Handle HTTP status codes
        status = resp.status_code
        if status == 200:
            try:
                data = resp.json()
                choices = data.get("choices", [])
                if not choices:
                    return self.make_error_response(
                        error_type="EmptyResponseError",
                        message="Response returned no completion choices."
                    )
                content = choices[0].get("message", {}).get("content", "")
                if content is None:
                    content = ""
                return self.make_success_response(
                    content=content.strip(),
                    model_used=data.get("model", self.model_name)
                )
            except (ValueError, KeyError) as parse_err:
                return self.make_error_response(
                    error_type="MalformedResponseError",
                    message=f"Failed to parse provider JSON response: {str(parse_err)}"
                )

        # Classify HTTP error responses
        try:
            err_data = resp.json()
            err_msg = err_data.get("error", {}).get("message", resp.text)
        except Exception:
            err_msg = resp.text or f"HTTP {status}"

        # Sanitize error message to ensure API key is never reflected
        if self.api_key:
            err_msg = err_msg.replace(self.api_key, "[REDACTED_KEY]")

        if status in (401, 403):
            return self.make_error_response(
                error_type="AuthenticationError",
                message=f"Authentication failed ({status}): {err_msg}"
            )
        elif status == 429:
            return self.make_error_response(
                error_type="RateLimitError",
                message=f"Rate limit or quota exceeded ({status}): {err_msg}"
            )
        elif status == 404:
            return self.make_error_response(
                error_type="NotFoundError",
                message=f"Model or endpoint not found ({status}): {err_msg}"
            )
        else:
            return self.make_error_response(
                error_type="APIError",
                message=f"Provider API returned error status {status}: {err_msg}"
            )
