"""
Unit tests for PeTTAAgentClient adapter.
File: tests/ui/test_agent_client.py
"""

import unittest
from pathlib import Path
from ui.agent_client import PeTTAAgentClient


class TestAgentClient(unittest.TestCase):

    def setUp(self):
        self.client = PeTTAAgentClient()

    def test_client_initialization(self):
        self.assertTrue(self.client.workspace_dir.exists())
        self.assertTrue(self.client.gateway_script.exists())
        self.assertTrue(self.client.feedback_script.exists())
        self.assertTrue(self.client.memory_dir.exists())

    def test_get_system_status(self):
        status = self.client.get_system_status()
        self.assertEqual(status["framework"], "PeTTa Agentic AI Framework")
        self.assertIn("PeTTa", status["runtime"])
        self.assertIn("llm_provider", status)
        self.assertIn("configured_model", status)
        self.assertTrue(len(status["tools"]) >= 5)
        self.assertTrue(len(status["skills"]) >= 3)
        self.assertIn("memory_records_count", status)
        self.assertIn("active_adaptations_count", status)

    def test_clear_conversation(self):
        # Create dummy conversation file
        self.client.conversation_file.write_text("user\tHello\nassistant\tHi\n", encoding="utf-8")
        self.assertTrue(self.client.clear_conversation())
        self.assertEqual(self.client.conversation_file.read_text(encoding="utf-8"), "")

    def test_submit_feedback_gateway(self):
        res = self.client.submit_feedback(
            category="answer_quality",
            polarity="positive",
            text="Very clear and concise explanation",
            target_type="answer",
            rating=1.0
        )
        self.assertIn("success", res)
        self.assertIn("message", res)


if __name__ == "__main__":
    unittest.main()
