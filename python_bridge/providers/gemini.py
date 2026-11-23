"""
Google Gemini Provider Adapter for PeTTa Python LLM Bridge.
Integrates with google.generativeai with REST transport, timeout controls,
and bounded model fallback logic.
"""

import warnings
warnings.filterwarnings("ignore")

import google.generativeai as genai
from typing import Dict, Any, Optional

from python_bridge.providers.base import BaseLLMProvider
from python_bridge.config import LLMConfig

class GeminiProvider(BaseLLMProvider):
    """
    Adapter for Google Gemini API using REST transport.
    """

    def __init__(self, config: LLMConfig):
        super().__init__(
            provider_name="gemini",
            model_name=config.gemini_model,
            timeout=config.llm_timeout
        )
        self.config = config
        self._initialized = False
        self._init_error: Optional[str] = None

        if not self.config.gemini_api_key:
            self._init_error = "GEMINI_API_KEY is missing or empty in configuration."
        else:
            try:
                genai.configure(api_key=self.config.gemini_api_key, transport="rest")
                self._initialized = True
            except Exception as e:
                self._init_error = f"Failed to initialize Gemini SDK: {str(e)}"

    def query(self, prompt: str) -> Dict[str, Any]:
        """
        Sends prompt to Gemini, handling timeouts, rate limits, and bounded fallback.
        """
        if not self._initialized:
            return self.make_error_response(
                error_type="AuthenticationError",
                message=self._init_error or "Gemini provider not properly configured."
            )

        if not prompt or not prompt.strip():
            return self.make_error_response(
                error_type="InvalidPromptError",
                message="Prompt cannot be empty."
            )

        # Primary attempt with configured model
        models_to_try = [self.model_name]
        if self.config.gemini_fallback_model and self.config.gemini_fallback_model != self.model_name and self.config.llm_max_retries > 0:
            models_to_try.append(self.config.gemini_fallback_model)

        last_error_type = "APIError"
        last_error_msg = "Unknown Gemini error occurred."

        for idx, model_candidate in enumerate(models_to_try):
            try:
                model = genai.GenerativeModel(model_candidate)
                response = model.generate_content(
                    prompt,
                    request_options={"timeout": self.timeout}
                )
                if response and hasattr(response, "text") and response.text:
                    return self.make_success_response(
                        content=response.text.strip(),
                        model_used=model_candidate
                    )
                else:
                    last_error_type = "EmptyResponseError"
                    last_error_msg = f"Model {model_candidate} returned empty or filtered content."
            except Exception as exc:
                err_str = str(exc)
                lower_err = err_str.lower()

                # Categorize errors strictly
                if "api key" in lower_err or "unauthenticated" in lower_err or "permission" in lower_err or "401" in lower_err or "403" in lower_err:
                    # Non-retryable authentication failure
                    return self.make_error_response(
                        error_type="AuthenticationError",
                        message="API authentication rejected: invalid credentials or insufficient permissions.",
                        model_used=model_candidate
                    )
                elif "quota" in lower_err or "resourceexhausted" in lower_err or "429" in lower_err:
                    # Non-retryable quota failure
                    return self.make_error_response(
                        error_type="RateLimitError",
                        message=f"Quota exhausted or rate limit exceeded on {model_candidate}.",
                        model_used=model_candidate
                    )
                elif "timed out" in lower_err or "deadline" in lower_err or "timeout" in lower_err:
                    last_error_type = "TimeoutError"
                    last_error_msg = f"Request timed out after {self.timeout} seconds."
                elif "connection" in lower_err or "dns" in lower_err or "network" in lower_err:
                    last_error_type = "NetworkError"
                    last_error_msg = f"Network connection failed: {err_str}"
                elif "not found" in lower_err or "404" in lower_err:
                    last_error_type = "ModelNotFoundError"
                    last_error_msg = f"Model {model_candidate} not found or unsupported."
                else:
                    last_error_type = "APIError"
                    last_error_msg = f"API error on {model_candidate}: {err_str}"

                # Only retry if next candidate exists and not an auth/quota issue
                if idx < len(models_to_try) - 1:
                    continue

        return self.make_error_response(
            error_type=last_error_type,
            message=last_error_msg,
            model_used=models_to_try[-1]
        )
