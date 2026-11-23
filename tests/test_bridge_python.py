"""
Unit and Mocked Provider Tests for PeTTa Python LLM Bridge.
Tests 1 to 15 per Milestone 4 specifications.
"""

import os
import sys
import json
import unittest
from pathlib import Path
from unittest.mock import patch, MagicMock

# Ensure project root is in sys.path
PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from python_bridge import bridge, config
from python_bridge.config import LLMConfig, load_config
from python_bridge.providers.gemini import GeminiProvider

class TestPythonBridge(unittest.TestCase):

    def setUp(self):
        bridge._providers.clear()

    # Test 1: Default configuration loading
    def test_01_default_config_loading(self):
        cfg = load_config()
        self.assertIsInstance(cfg, LLMConfig)
        self.assertEqual(cfg.llm_provider, "gemini")
        self.assertIn("gemini-", cfg.gemini_model)
        self.assertGreater(cfg.llm_timeout, 0)

    # Test 2: Custom configuration loading
    def test_02_custom_config_loading(self):
        custom_cfg = LLMConfig(
            gemini_api_key="custom_test_key",
            gemini_model="custom-model-v1",
            gemini_fallback_model="custom-fallback-v1",
            llm_timeout=45,
            llm_max_retries=2
        )
        self.assertEqual(custom_cfg.gemini_model, "custom-model-v1")
        self.assertEqual(custom_cfg.llm_timeout, 45)
        self.assertEqual(custom_cfg.llm_max_retries, 2)

    # Test 3: Missing API key handling
    def test_03_missing_api_key_handling(self):
        empty_cfg = LLMConfig(gemini_api_key="")
        provider = GeminiProvider(empty_cfg)
        resp = provider.query("Hello")
        self.assertFalse(resp["success"])
        self.assertEqual(resp["error"]["type"], "AuthenticationError")
        self.assertIn("missing", resp["error"]["message"].lower())

    # Test 4: Invalid provider handling
    def test_04_invalid_provider(self):
        raw = bridge.query("unsupported_provider", "Hello")
        data = json.loads(raw)
        self.assertFalse(data["success"])
        self.assertEqual(data["error"]["type"], "UnsupportedProviderError")

    # Test 5: Empty or whitespace prompt handling
    def test_05_empty_prompt_handling(self):
        cfg = LLMConfig(gemini_api_key="valid_test_key")
        provider = GeminiProvider(cfg)
        resp = provider.query("   ")
        self.assertFalse(resp["success"])
        self.assertEqual(resp["error"]["type"], "InvalidPromptError")

    # Test 6: Gemini adapter initialization
    def test_06_adapter_initialization(self):
        cfg = LLMConfig(gemini_api_key="valid_key_123", gemini_model="gemini-3.5-flash-lite")
        provider = GeminiProvider(cfg)
        self.assertEqual(provider.provider_name, "gemini")
        self.assertEqual(provider.model_name, "gemini-3.5-flash-lite")
        self.assertTrue(provider._initialized)

    # Test 7: Successful mocked response
    @patch("google.generativeai.GenerativeModel")
    def test_07_successful_mocked_response(self, mock_model_cls):
        mock_instance = MagicMock()
        mock_response = MagicMock()
        mock_response.text = "Agentic AI refers to autonomous goal-driven systems."
        mock_instance.generate_content.return_value = mock_response
        mock_model_cls.return_value = mock_instance

        cfg = LLMConfig(gemini_api_key="valid_test_key", gemini_model="gemini-3.5-flash-lite")
        provider = GeminiProvider(cfg)
        resp = provider.query("What is Agentic AI?")

        self.assertTrue(resp["success"])
        self.assertIn("autonomous goal-driven", resp["content"])
        self.assertIsNone(resp["error"])

    # Test 8: Authentication error does not retry
    @patch("google.generativeai.GenerativeModel")
    def test_08_authentication_error_no_retry(self, mock_model_cls):
        mock_instance = MagicMock()
        mock_instance.generate_content.side_effect = Exception("401 Unauthorized API key not valid")
        mock_model_cls.return_value = mock_instance

        cfg = LLMConfig(gemini_api_key="bad_key", gemini_fallback_model="fallback-model")
        provider = GeminiProvider(cfg)
        resp = provider.query("Hello")

        self.assertFalse(resp["success"])
        self.assertEqual(resp["error"]["type"], "AuthenticationError")
        # Ensure it was called only once (no fallback for auth error)
        self.assertEqual(mock_model_cls.call_count, 1)

    # Test 9: Rate limit error does not retry
    @patch("google.generativeai.GenerativeModel")
    def test_09_rate_limit_error_no_retry(self, mock_model_cls):
        mock_instance = MagicMock()
        mock_instance.generate_content.side_effect = Exception("429 ResourceExhausted: quota exceeded")
        mock_model_cls.return_value = mock_instance

        cfg = LLMConfig(gemini_api_key="valid_key", gemini_fallback_model="fallback-model")
        provider = GeminiProvider(cfg)
        resp = provider.query("Hello")

        self.assertFalse(resp["success"])
        self.assertEqual(resp["error"]["type"], "RateLimitError")
        self.assertEqual(mock_model_cls.call_count, 1)

    # Test 10: Timeout error handling
    @patch("google.generativeai.GenerativeModel")
    def test_10_timeout_error_handling(self, mock_model_cls):
        mock_instance = MagicMock()
        mock_instance.generate_content.side_effect = Exception("DeadlineExceeded: request timed out")
        mock_model_cls.return_value = mock_instance

        cfg = LLMConfig(gemini_api_key="valid_key", gemini_fallback_model=None, llm_max_retries=0)
        provider = GeminiProvider(cfg)
        resp = provider.query("Hello")

        self.assertFalse(resp["success"])
        self.assertEqual(resp["error"]["type"], "TimeoutError")

    # Test 11: Network connection error handling
    @patch("google.generativeai.GenerativeModel")
    def test_11_network_error_handling(self, mock_model_cls):
        mock_instance = MagicMock()
        mock_instance.generate_content.side_effect = Exception("ConnectionRefused: failed to resolve host")
        mock_model_cls.return_value = mock_instance

        cfg = LLMConfig(gemini_api_key="valid_key", gemini_fallback_model=None, llm_max_retries=0)
        provider = GeminiProvider(cfg)
        resp = provider.query("Hello")

        self.assertFalse(resp["success"])
        self.assertEqual(resp["error"]["type"], "NetworkError")

    # Test 12: Bounded model fallback on transient error
    @patch("google.generativeai.GenerativeModel")
    def test_12_bounded_model_fallback(self, mock_model_cls):
        primary_mock = MagicMock()
        primary_mock.generate_content.side_effect = Exception("404 Model not found")

        fallback_mock = MagicMock()
        fallback_resp = MagicMock()
        fallback_resp.text = "Response from fallback model."
        fallback_mock.generate_content.return_value = fallback_resp

        mock_model_cls.side_effect = [primary_mock, fallback_mock]

        cfg = LLMConfig(
            gemini_api_key="valid_key",
            gemini_model="gemini-old",
            gemini_fallback_model="gemini-fallback",
            llm_max_retries=1
        )
        provider = GeminiProvider(cfg)
        resp = provider.query("Hello")

        self.assertTrue(resp["success"])
        self.assertEqual(resp["model"], "gemini-fallback")
        self.assertEqual(mock_model_cls.call_count, 2)

    # Test 13: Schema consistency for success and error
    def test_13_schema_consistency(self):
        cfg = LLMConfig(gemini_api_key="valid_key")
        provider = GeminiProvider(cfg)
        succ = provider.make_success_response("text")
        err = provider.make_error_response("SomeError", "message")

        expected_keys = {"success", "provider", "model", "content", "error"}
        self.assertEqual(set(succ.keys()), expected_keys)
        self.assertEqual(set(err.keys()), expected_keys)
        self.assertTrue(succ["success"])
        self.assertFalse(err["success"])
        self.assertIsNone(succ["error"])
        self.assertIsNone(err["content"])

    # Test 14: Secret sanitization test
    def test_14_secret_sanitization(self):
        raw_secret = "AIzaSySecretApiKey123456789"
        cfg = LLMConfig(gemini_api_key=raw_secret)
        repr_str = repr(cfg)
        self.assertNotIn(raw_secret, repr_str)
        self.assertIn("[CONFIGURED]", repr_str)

        provider = GeminiProvider(cfg)
        err = provider.make_error_response("AuthError", f"Failed with {raw_secret}")
        self.assertNotIn(raw_secret, json.dumps(err))

    # Test 15: Configuration loading independent of working directory
    def test_15_directory_independent_loading(self):
        # Even if loaded from root, config locates DEFAULT_ENV_PATH correctly
        cfg = load_config()
        self.assertTrue(cfg.gemini_model)
        self.assertIsInstance(cfg.llm_timeout, int)

if __name__ == "__main__":
    unittest.main()
