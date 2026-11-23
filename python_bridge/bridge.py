"""
Public Entry Point for PeTTa Python LLM Bridge.
Implements query(provider, prompt) -> str and get_field(response_json, field_name).
Contains essential Janus path bootstrapping to guarantee reliable embedded imports.
"""

import os
import sys
import json
from pathlib import Path
from typing import Any, Optional

# ==============================================================================
# Essential Path Bootstrapping for SWI-Prolog Janus Embedded Execution
# ==============================================================================
_BRIDGE_DIR = Path(__file__).resolve().parent
_PROJECT_ROOT = _BRIDGE_DIR.parent
_VENV_PKGS = _PROJECT_ROOT / ".venv" / "lib" / f"python{sys.version_info.major}.{sys.version_info.minor}" / "site-packages"

for _path in (_VENV_PKGS, _PROJECT_ROOT, _BRIDGE_DIR):
    if _path.exists() and str(_path) not in sys.path:
        sys.path.insert(0, str(_path))

from python_bridge.config import load_config, LLMConfig
from python_bridge.providers.gemini import GeminiProvider
from python_bridge.providers.generic_openai import GenericOpenAIProvider
from python_bridge.providers.openai import OpenAIProvider
from python_bridge.providers.deepseek import DeepSeekProvider

# Active provider cache
_providers = {}

def get_provider(provider_name: str, config: Optional[LLMConfig] = None):
    """
    Returns an initialized provider adapter singleton.
    Supports 'gemini', 'openai', 'deepseek', 'generic_openai' (or 'generic'),
    and 'default' (resolves to config.llm_provider).
    """
    raw_key = provider_name.lower().strip()
    active_config = config or load_config()

    if raw_key in ("default", ""):
        resolved_key = active_config.llm_provider.lower().strip() or "gemini"
    else:
        resolved_key = raw_key

    cache_key = f"{resolved_key}_{id(config)}" if config else resolved_key
    if cache_key in _providers and config is None:
        return _providers[cache_key]

    adapter = None
    if resolved_key == "gemini":
        adapter = GeminiProvider(active_config)
    elif resolved_key == "openai":
        adapter = OpenAIProvider(active_config)
    elif resolved_key == "deepseek":
        adapter = DeepSeekProvider(active_config)
    elif resolved_key in ("generic_openai", "generic"):
        adapter = GenericOpenAIProvider(active_config)

    if adapter is not None and config is None:
        _providers[cache_key] = adapter

    return adapter

def query(provider: str, prompt: str) -> str:
    """
    Public bridge interface callable from PeTTa via (py-call (bridge.query provider prompt)).
    Returns a normalized JSON string conforming to the approved contract.
    """
    if not provider or not isinstance(provider, str):
        return json.dumps({
            "success": False,
            "provider": str(provider),
            "model": "unknown",
            "content": None,
            "error": {
                "type": "UnsupportedProviderError",
                "message": f"Provider name must be a non-empty string, got '{provider}'."
            }
        })

    provider_clean = provider.strip().lower()
    adapter = get_provider(provider_clean)
    if adapter is None:
        return json.dumps({
            "success": False,
            "provider": provider_clean,
            "model": "unknown",
            "content": None,
            "error": {
                "type": "UnsupportedProviderError",
                "message": f"Provider '{provider}' is not supported. Supported: 'gemini', 'openai', 'deepseek', 'generic_openai', 'default'."
            }
        })

    try:
        result = adapter.query(prompt)
        return json.dumps(result)
    except Exception as exc:
        return json.dumps({
            "success": False,
            "provider": provider_clean,
            "model": getattr(adapter, "model_name", "unknown"),
            "content": None,
            "error": {
                "type": "UnhandledBridgeException",
                "message": f"Unexpected bridge exception: {str(exc)}"
            }
        })

def get_field(response_json: str, field_name: str) -> Any:
    """
    Safe transport decoding helper callable from PeTTa to extract JSON fields.
    Returns field value (or "null"/None on failure).
    """
    try:
        data = json.loads(response_json)
        val = data.get(field_name, None)
        # Normalize nested dictionaries (like error) to JSON string if needed
        if isinstance(val, dict):
            return json.dumps(val)
        return val
    except Exception:
        return None
