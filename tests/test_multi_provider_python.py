"""
Unit and Mocked Provider Tests for PeTTa Multi-Provider Python LLM Bridge.
Validates Milestone 5 additions: OpenAI, DeepSeek, GenericOpenAI, default routing,
endpoint normalization, error handling, secret masking, and Gemini regression.
"""

import sys
import json
import unittest
from pathlib import Path
from unittest.mock import patch, MagicMock

# Ensure project root is in sys.path
PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

import requests
from python_bridge import bridge
from python_bridge.config import LLMConfig, load_config
from python_bridge.providers.generic_openai import GenericOpenAIProvider
from python_bridge.providers.openai import OpenAIProvider
from python_bridge.providers.deepseek import DeepSeekProvider
from python_bridge.providers.gemini import GeminiProvider

class TestMultiProviderBridge(unittest.TestCase):

    def setUp(self):
        bridge._providers.clear()

    # Test 1: OpenAI Success via requests mock
    @patch("requests.post")
    def test_01_openai_success(self, mock_post):
        mock_resp = MagicMock()
        mock_resp.status_code = 200
        mock_resp.json.return_value = {
            "id": "chatcmpl-123",
            "model": "gpt-4o-mini",
            "choices": [{
                "message": {"role": "assistant", "content": "OpenAI says hello from PeTTa!"}
            }]
        }
        mock_post.return_value = mock_resp

        cfg = LLMConfig(openai_api_key="sk-test-key-openai", openai_model="gpt-4o-mini")
        provider = OpenAIProvider(cfg)
        result = provider.query("Hello OpenAI")

        self.assertTrue(result["success"])
        self.assertEqual(result["provider"], "openai")
        self.assertEqual(result["model"], "gpt-4o-mini")
        self.assertEqual(result["content"], "OpenAI says hello from PeTTa!")
        self.assertIsNone(result["error"])
        mock_post.assert_called_once()
        args, kwargs = mock_post.call_args
        self.assertEqual(args[0], "https://api.openai.com/v1/chat/completions")
        self.assertEqual(kwargs["headers"]["Authorization"], "Bearer sk-test-key-openai")

    # Test 2: DeepSeek Success via requests mock
    @patch("requests.post")
    def test_02_deepseek_success(self, mock_post):
        mock_resp = MagicMock()
        mock_resp.status_code = 200
        mock_resp.json.return_value = {
            "id": "deepseek-123",
            "model": "deepseek-chat",
            "choices": [{
                "message": {"role": "assistant", "content": "DeepSeek response content"}
            }]
        }
        mock_post.return_value = mock_resp

        cfg = LLMConfig(deepseek_api_key="sk-test-key-deepseek", deepseek_model="deepseek-chat")
        provider = DeepSeekProvider(cfg)
        result = provider.query("Hello DeepSeek")

        self.assertTrue(result["success"])
        self.assertEqual(result["provider"], "deepseek")
        self.assertEqual(result["model"], "deepseek-chat")
        self.assertEqual(result["content"], "DeepSeek response content")
        self.assertIsNone(result["error"])
        mock_post.assert_called_once()
        args, _ = mock_post.call_args
        self.assertEqual(args[0], "https://api.deepseek.com/chat/completions")

    # Test 3: Generic OpenAI Success via requests mock
    @patch("requests.post")
    def test_03_generic_success(self, mock_post):
        mock_resp = MagicMock()
        mock_resp.status_code = 200
        mock_resp.json.return_value = {
            "id": "gen-123",
            "model": "mistral-7b-instruct",
            "choices": [{
                "message": {"role": "assistant", "content": "Local model output"}
            }]
        }
        mock_post.return_value = mock_resp

        cfg = LLMConfig(
            generic_api_key="generic-key",
            generic_base_url="https://openrouter.ai/api/v1",
            generic_model="mistral-7b-instruct"
        )
        provider = GenericOpenAIProvider(cfg)
        result = provider.query("Hello Generic")

        self.assertTrue(result["success"])
        self.assertEqual(result["provider"], "generic_openai")
        self.assertEqual(result["model"], "mistral-7b-instruct")
        self.assertEqual(result["content"], "Local model output")

    # Test 4: Default provider routing to Gemini
    def test_04_default_routing_gemini(self):
        cfg = LLMConfig(llm_provider="gemini", gemini_api_key="dummy_gemini_key")
        adapter = bridge.get_provider("default", cfg)
        self.assertIsInstance(adapter, GeminiProvider)
        self.assertEqual(adapter.provider_name, "gemini")

    # Test 5: Default provider routing to OpenAI
    def test_05_default_routing_openai(self):
        cfg = LLMConfig(llm_provider="openai", openai_api_key="dummy_openai_key")
        adapter = bridge.get_provider("default", cfg)
        self.assertIsInstance(adapter, OpenAIProvider)
        self.assertEqual(adapter.provider_name, "openai")

    # Test 6: Default provider routing to DeepSeek
    def test_06_default_routing_deepseek(self):
        cfg = LLMConfig(llm_provider="deepseek", deepseek_api_key="dummy_deepseek_key")
        adapter = bridge.get_provider("default", cfg)
        self.assertIsInstance(adapter, DeepSeekProvider)
        self.assertEqual(adapter.provider_name, "deepseek")

    # Test 7: Default provider routing to Generic
    def test_07_default_routing_generic(self):
        cfg = LLMConfig(
            llm_provider="generic_openai",
            generic_api_key="dummy_generic_key",
            generic_base_url="http://localhost:11434/v1"
        )
        adapter = bridge.get_provider("default", cfg)
        self.assertIsInstance(adapter, GenericOpenAIProvider)
        self.assertEqual(adapter.provider_name, "generic_openai")

    # Test 8: OpenAI missing API key error
    def test_08_openai_missing_api_key(self):
        cfg = LLMConfig(openai_api_key="")
        provider = OpenAIProvider(cfg)
        result = provider.query("Prompt")
        self.assertFalse(result["success"])
        self.assertEqual(result["error"]["type"], "AuthenticationError")
        self.assertIn("API key is missing", result["error"]["message"])

    # Test 9: DeepSeek missing API key error
    def test_09_deepseek_missing_api_key(self):
        cfg = LLMConfig(deepseek_api_key="")
        provider = DeepSeekProvider(cfg)
        result = provider.query("Prompt")
        self.assertFalse(result["success"])
        self.assertEqual(result["error"]["type"], "AuthenticationError")
        self.assertIn("API key is missing", result["error"]["message"])

    # Test 10: Generic missing base URL error
    def test_10_generic_missing_base_url(self):
        cfg = LLMConfig(generic_api_key="key123", generic_base_url="")
        provider = GenericOpenAIProvider(cfg)
        result = provider.query("Prompt")
        self.assertFalse(result["success"])
        self.assertEqual(result["error"]["type"], "ConfigurationError")
        self.assertIn("Missing required base URL", result["error"]["message"])

    # Test 11: Generic missing API key for remote host
    def test_11_generic_missing_key_remote(self):
        cfg = LLMConfig(generic_api_key="", generic_base_url="https://api.example.com/v1")
        provider = GenericOpenAIProvider(cfg)
        result = provider.query("Prompt")
        self.assertFalse(result["success"])
        self.assertEqual(result["error"]["type"], "AuthenticationError")

    # Test 12: Generic local endpoint allows empty key (e.g. Ollama/vLLM)
    @patch("requests.post")
    def test_12_generic_local_endpoint_no_key(self, mock_post):
        mock_resp = MagicMock()
        mock_resp.status_code = 200
        mock_resp.json.return_value = {
            "choices": [{"message": {"content": "Local Ollama response"}}]
        }
        mock_post.return_value = mock_resp

        cfg = LLMConfig(generic_api_key="", generic_base_url="http://localhost:11434/v1")
        provider = GenericOpenAIProvider(cfg)
        result = provider.query("Prompt")
        self.assertTrue(result["success"])
        self.assertEqual(result["content"], "Local Ollama response")

    # Test 13: HTTP 401 returns AuthenticationError
    @patch("requests.post")
    def test_13_http_401_authentication_error(self, mock_post):
        mock_resp = MagicMock()
        mock_resp.status_code = 401
        mock_resp.json.return_value = {"error": {"message": "Incorrect API key provided."}}
        mock_post.return_value = mock_resp

        cfg = LLMConfig(openai_api_key="sk-invalid")
        provider = OpenAIProvider(cfg)
        result = provider.query("Prompt")
        self.assertFalse(result["success"])
        self.assertEqual(result["error"]["type"], "AuthenticationError")
        self.assertIn("Authentication failed", result["error"]["message"])

    # Test 14: HTTP 429 returns RateLimitError
    @patch("requests.post")
    def test_14_http_429_rate_limit(self, mock_post):
        mock_resp = MagicMock()
        mock_resp.status_code = 429
        mock_resp.json.return_value = {"error": {"message": "You exceeded your current quota."}}
        mock_post.return_value = mock_resp

        cfg = LLMConfig(deepseek_api_key="sk-quota-exceeded")
        provider = DeepSeekProvider(cfg)
        result = provider.query("Prompt")
        self.assertFalse(result["success"])
        self.assertEqual(result["error"]["type"], "RateLimitError")
        self.assertIn("Rate limit or quota exceeded", result["error"]["message"])

    # Test 15: Timeout returns TimeoutError
    @patch("requests.post", side_effect=requests.exceptions.Timeout("Read timed out"))
    def test_15_timeout_error(self, mock_post):
        cfg = LLMConfig(openai_api_key="sk-test-key")
        provider = OpenAIProvider(cfg)
        result = provider.query("Prompt")
        self.assertFalse(result["success"])
        self.assertEqual(result["error"]["type"], "TimeoutError")
        self.assertIn("timed out", result["error"]["message"])

    # Test 16: Connection error returns NetworkError
    @patch("requests.post", side_effect=requests.exceptions.ConnectionError("Connection refused"))
    def test_16_connection_error(self, mock_post):
        cfg = LLMConfig(openai_api_key="sk-test-key")
        provider = OpenAIProvider(cfg)
        result = provider.query("Prompt")
        self.assertFalse(result["success"])
        self.assertEqual(result["error"]["type"], "NetworkError")

    # Test 17: URL Normalization
    def test_17_endpoint_url_normalization(self):
        norm = GenericOpenAIProvider._normalize_endpoint
        self.assertEqual(norm("https://api.openai.com/v1/"), "https://api.openai.com/v1/chat/completions")
        self.assertEqual(norm("https://api.openai.com/v1"), "https://api.openai.com/v1/chat/completions")
        self.assertEqual(norm("https://api.openai.com/v1/chat/completions"), "https://api.openai.com/v1/chat/completions")
        self.assertEqual(norm("http://localhost:11434/v1/"), "http://localhost:11434/v1/chat/completions")
        self.assertEqual(norm(""), "")

    # Test 18: API Key Sanitization in error responses
    @patch("requests.post")
    def test_18_api_key_redacted_in_errors(self, mock_post):
        secret = "sk-super-secret-key-999"
        mock_resp = MagicMock()
        mock_resp.status_code = 400
        mock_resp.json.return_value = {"error": {"message": f"Bad request with key {secret}"}}
        mock_post.return_value = mock_resp

        cfg = LLMConfig(openai_api_key=secret)
        provider = OpenAIProvider(cfg)
        result = provider.query("Prompt")

        self.assertFalse(result["success"])
        self.assertNotIn(secret, result["error"]["message"])
        self.assertIn("[REDACTED_KEY]", result["error"]["message"])

    # Test 19: Empty choices response handling
    @patch("requests.post")
    def test_19_empty_choices(self, mock_post):
        mock_resp = MagicMock()
        mock_resp.status_code = 200
        mock_resp.json.return_value = {"choices": []}
        mock_post.return_value = mock_resp

        cfg = LLMConfig(openai_api_key="sk-test")
        provider = OpenAIProvider(cfg)
        result = provider.query("Prompt")
        self.assertFalse(result["success"])
        self.assertEqual(result["error"]["type"], "EmptyResponseError")

    # Test 20: Gemini Regression Verification
    def test_20_gemini_regression(self):
        adapter = bridge.get_provider("gemini")
        self.assertIsInstance(adapter, GeminiProvider)
        self.assertEqual(adapter.provider_name, "gemini")

if __name__ == "__main__":
    unittest.main()
