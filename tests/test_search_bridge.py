"""
Automated unit tests for python_bridge.search_bridge
File: tests/test_search_bridge.py
"""

import unittest
import json
from unittest.mock import patch, MagicMock
from python_bridge.search_bridge import (
    query_search,
    format_search_observation,
    _sanitize_string
)


class TestSearchBridge(unittest.TestCase):

    def test_sanitize_string(self):
        secret = "Bearer AIzaSyAbc1234567890SecretKey"
        sanitized = _sanitize_string(secret)
        self.assertNotIn("AIzaSyAbc1234567890SecretKey", sanitized)
        self.assertIn("[REDACTED]", sanitized)

    def test_empty_query(self):
        res = query_search("")
        data = json.loads(res)
        self.assertEqual(data["status"], "error")

    @patch("python_bridge.search_bridge.urllib.request.urlopen")
    def test_mocked_tavily_search(self, mock_urlopen):
        mock_resp = MagicMock()
        mock_resp.read.return_value = json.dumps({
            "results": [
                {"title": "Test Title", "url": "https://example.com/test", "content": "Sample snippet content."}
            ]
        }).encode("utf-8")
        mock_urlopen.return_value.__enter__.return_value = mock_resp

        with patch.dict("os.environ", {"TAVILY_API_KEY": "tvly-test-key-1234567890"}):
            raw = query_search("PeTTa AI", max_results=1)
            data = json.loads(raw)
            self.assertEqual(data["status"], "success")
            self.assertEqual(data["provider"], "tavily")
            self.assertEqual(len(data["results"]), 1)
            self.assertEqual(data["results"][0]["title"], "Test Title")

    @patch("python_bridge.search_bridge.urllib.request.urlopen")
    def test_mocked_brave_search(self, mock_urlopen):
        mock_resp = MagicMock()
        mock_resp.read.return_value = json.dumps({
            "web": {
                "results": [
                    {"title": "Brave Result", "url": "https://brave.example.com", "description": "Brave snippet"}
                ]
            }
        }).encode("utf-8")
        mock_urlopen.return_value.__enter__.return_value = mock_resp

        with patch.dict("os.environ", {"BRAVE_API_KEY": "brave-key-1234567890", "TAVILY_API_KEY": ""}):
            raw = query_search("PeTTa AI", max_results=1)
            data = json.loads(raw)
            self.assertEqual(data["status"], "success")
            self.assertEqual(data["provider"], "brave")
            self.assertEqual(len(data["results"]), 1)

    def test_format_search_observation(self):
        mock_json = json.dumps({
            "status": "success",
            "query": "laptop CS",
            "results": [
                {"title": "Dell XPS 13", "url": "https://dell.com", "snippet": "Compact laptop with 16GB RAM"}
            ]
        })
        obs = format_search_observation(mock_json)
        self.assertIn("Found 1 web search result(s)", obs)
        self.assertIn("[Dell XPS 13](https://dell.com)", obs)


if __name__ == "__main__":
    unittest.main()
