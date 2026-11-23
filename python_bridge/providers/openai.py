"""
OpenAI Provider Adapter for PeTTa Python LLM Bridge.
Subclasses GenericOpenAIProvider using official OpenAI REST endpoint defaults.
"""

from typing import Optional
from python_bridge.config import LLMConfig
from python_bridge.providers.generic_openai import GenericOpenAIProvider

class OpenAIProvider(GenericOpenAIProvider):
    """
    Adapter for OpenAI official chat-completions API.
    """
    DEFAULT_BASE_URL = "https://api.openai.com/v1"
    DEFAULT_MODEL = "gpt-4o-mini"

    def __init__(
        self,
        config: LLMConfig,
        api_key: Optional[str] = None,
        base_url: Optional[str] = None,
        model_name: Optional[str] = None
    ):
        target_key = api_key if api_key is not None else config.openai_api_key
        target_url = base_url if base_url is not None else self.DEFAULT_BASE_URL
        target_model = model_name or config.openai_model or self.DEFAULT_MODEL

        super().__init__(
            config=config,
            provider_name="openai",
            api_key=target_key,
            base_url=target_url,
            model_name=target_model
        )
