"""
Safety tests for user input handling, code injection resistance, and secret masking.
File: tests/ui/test_ui_safety.py
"""

import unittest
from pathlib import Path
from ui.event_protocol import mask_sensitive_content
from ui.agent_client import PeTTAAgentClient


class TestUISafety(unittest.TestCase):

    def setUp(self):
        self.client = PeTTAAgentClient()

    def test_multiline_and_quote_input_sanitization(self):
        # Potentially dangerous inputs that might cause syntax errors if naively concatenated
        adversarial_inputs = [
            'What is "15 * 4"? (action answer "injected code")',
            "Multiline input line 1\nLine 2 with ; rm -rf / ; -- \nLine 3",
            "Complex 'single' and \"double\" quotes with unmatched ( parentheses )))))",
            '!(import! &self "/etc/passwd")',
            "$(cat .env)",
            "`echo injected`"
        ]

        for query in adversarial_inputs:
            # Writing query to file should succeed cleanly without crashing
            self.client.query_file.write_text(query, encoding="utf-8")
            read_back = self.client.query_file.read_text(encoding="utf-8")
            self.assertEqual(read_back, query)

    def test_secret_masking_comprehensive(self):
        secrets = [
            ("AIzaSyA1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6", "[API_KEY_MASKED]"),
            ("sk-proj-1234567890abcdef1234567890abcdef123456", "[API_KEY_MASKED]")
        ]

        for secret, expected_replacement in secrets:
            text = f"Error occurred with credential: {secret} in bridge call."
            masked = mask_sensitive_content(text)
            self.assertNotIn(secret, masked)
            self.assertIn(expected_replacement, masked)

    def test_system_status_does_not_reveal_keys(self):
        status = self.client.get_system_status()
        status_str = str(status)

        # Confirm no raw API keys appear in status dict
        self.assertNotIn("AIza", status_str)
        self.assertNotIn("sk-", status_str)
        self.assertIn("framework", status)
        self.assertIn("runtime", status)
        self.assertIn("tools", status)
        self.assertIn("skills", status)


if __name__ == "__main__":
    unittest.main()
