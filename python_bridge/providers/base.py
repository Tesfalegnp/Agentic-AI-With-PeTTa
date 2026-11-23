"""
Base Abstract Provider Definition for PeTTa LLM Bridge.
Enforces uniform response contract across all provider adapters.
"""

from abc import ABC, abstractmethod
from typing import Dict, Any, Optional

class BaseLLMProvider(ABC):
    """
    Abstract Base Class for LLM Provider Adapters.
    """

    def __init__(self, provider_name: str, model_name: str, timeout: int = 30):
        self.provider_name = provider_name
        self.model_name = model_name
        self.timeout = timeout

    @abstractmethod
    def query(self, prompt: str) -> Dict[str, Any]:
        """
        Executes query against LLM provider. Must return normalized dict conforming to contract.
        """
        pass

    def make_success_response(self, content: str, model_used: Optional[str] = None) -> Dict[str, Any]:
        """
        Constructs normalized success dictionary.
        """
        return {
            "success": True,
            "provider": self.provider_name,
            "model": model_used or self.model_name,
            "content": content,
            "error": None
        }

    def make_error_response(self, error_type: str, message: str, model_used: Optional[str] = None) -> Dict[str, Any]:
        """
        Constructs normalized error dictionary.
        """
        # Ensure message never exposes API key strings
        sanitized_msg = str(message).replace("AIzaSy", "[REDACTED_KEY]")
        return {
            "success": False,
            "provider": self.provider_name,
            "model": model_used or self.model_name,
            "content": None,
            "error": {
                "type": error_type,
                "message": sanitized_msg
            }
        }
