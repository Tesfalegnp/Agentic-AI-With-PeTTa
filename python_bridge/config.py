"""
Configuration Management for PeTTa Python LLM Bridge.
Directory-independent environment variable loading and secret sanitization
supporting multi-provider settings (Gemini, OpenAI, DeepSeek, Generic).
"""

import os
from pathlib import Path
from dataclasses import dataclass
from typing import Optional
from dotenv import load_dotenv

_BRIDGE_DIR = Path(__file__).resolve().parent
_PROJECT_ROOT = _BRIDGE_DIR.parent
DEFAULT_ENV_PATH = _PROJECT_ROOT / ".env"

@dataclass
class LLMConfig:
    # Google Gemini
    gemini_api_key: str = ""
    gemini_model: str = "gemini-3.5-flash-lite"
    gemini_fallback_model: Optional[str] = "gemini-3-flash-preview"
    
    # OpenAI
    openai_api_key: str = ""
    openai_model: str = "gpt-4o-mini"
    
    # DeepSeek
    deepseek_api_key: str = ""
    deepseek_model: str = "deepseek-chat"
    
    # Generic OpenAI-Compatible
    generic_api_key: str = ""
    generic_base_url: str = ""
    generic_model: str = "default-model"
    
    # Common settings
    llm_provider: str = "gemini"
    llm_timeout: int = 30
    llm_max_retries: int = 1

    def __repr__(self) -> str:
        # Never leak API keys in repr or string conversions
        m_gemini = "[CONFIGURED]" if self.gemini_api_key else "[MISSING]"
        m_openai = "[CONFIGURED]" if self.openai_api_key else "[MISSING]"
        m_deepseek = "[CONFIGURED]" if self.deepseek_api_key else "[MISSING]"
        m_generic = "[CONFIGURED]" if self.generic_api_key else "[MISSING]"
        return (
            f"LLMConfig(provider='{self.llm_provider}', timeout={self.llm_timeout}, retries={self.llm_max_retries}, "
            f"gemini(model='{self.gemini_model}', key={m_gemini}), "
            f"openai(model='{self.openai_model}', key={m_openai}), "
            f"deepseek(model='{self.deepseek_model}', key={m_deepseek}), "
            f"generic(base_url='{self.generic_base_url}', model='{self.generic_model}', key={m_generic}))"
        )

def load_config(env_path: Optional[Path] = None) -> LLMConfig:
    """
    Loads configuration from .env file securely regardless of current working directory.
    """
    target_env = env_path if env_path is not None else DEFAULT_ENV_PATH
    if target_env.exists():
        load_dotenv(dotenv_path=target_env, override=False)
    
    # Common settings
    provider = os.environ.get("LLM_PROVIDER", "gemini").strip().lower()
    
    try:
        timeout = int(os.environ.get("LLM_TIMEOUT", "30").strip())
    except ValueError:
        timeout = 30
        
    try:
        max_retries = int(os.environ.get("LLM_MAX_RETRIES", "1").strip())
    except ValueError:
        max_retries = 1

    # Gemini settings
    gemini_key = os.environ.get("GEMINI_API_KEY", "").strip()
    gemini_model = os.environ.get("GEMINI_MODEL", "gemini-3.5-flash-lite").strip()
    gemini_fallback = os.environ.get("GEMINI_FALLBACK_MODEL", "gemini-3-flash-preview").strip()

    # OpenAI settings
    openai_key = os.environ.get("OPENAI_API_KEY", "").strip()
    openai_model = os.environ.get("OPENAI_MODEL", "gpt-4o-mini").strip()

    # DeepSeek settings
    deepseek_key = os.environ.get("DEEPSEEK_API_KEY", "").strip()
    deepseek_model = os.environ.get("DEEPSEEK_MODEL", "deepseek-chat").strip()

    # Generic settings
    generic_key = os.environ.get("GENERIC_API_KEY", "").strip()
    generic_url = os.environ.get("GENERIC_BASE_URL", "").strip()
    generic_model = os.environ.get("GENERIC_MODEL", "default-model").strip()

    return LLMConfig(
        gemini_api_key=gemini_key,
        gemini_model=gemini_model if gemini_model else "gemini-3.5-flash-lite",
        gemini_fallback_model=gemini_fallback if gemini_fallback else None,
        openai_api_key=openai_key,
        openai_model=openai_model if openai_model else "gpt-4o-mini",
        deepseek_api_key=deepseek_key,
        deepseek_model=deepseek_model if deepseek_model else "deepseek-chat",
        generic_api_key=generic_key,
        generic_base_url=generic_url,
        generic_model=generic_model if generic_model else "default-model",
        llm_provider=provider if provider else "gemini",
        llm_timeout=timeout,
        llm_max_retries=max_retries
    )
