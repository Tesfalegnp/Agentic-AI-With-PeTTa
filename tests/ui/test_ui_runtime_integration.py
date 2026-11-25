"""
Live runtime integration tests connecting PeTTAAgentClient to the real PeTTa engine.
File: tests/ui/test_ui_runtime_integration.py

NOTE: These tests require a configured LLM API key (GEMINI_API_KEY, OPENAI_API_KEY,
or DEEPSEEK_API_KEY) and a working PeTTa installation to pass.
Without credentials, they are skipped automatically.
"""

import os
import unittest
import time
from ui.agent_client import PeTTAAgentClient
from ui.event_protocol import AgentEvent, AgentExecutionResult

SKIP_LIVE = not any([
    os.environ.get("GEMINI_API_KEY", ""),
    os.environ.get("OPENAI_API_KEY", ""),
    os.environ.get("DEEPSEEK_API_KEY", ""),
])
SKIP_REASON = "No LLM API key configured — skipping live integration tests."


class TestUIClientUnit(unittest.TestCase):
    """Non-network unit tests for the agent client adapter."""

    def setUp(self):
        self.client = PeTTAAgentClient()

    def test_client_instantiates(self):
        self.assertIsNotNone(self.client)
        self.assertTrue(self.client.workspace_dir.exists())

    def test_memory_dir_created(self):
        self.assertTrue(self.client.memory_dir.exists())

    def test_clear_conversation_runs(self):
        result = self.client.clear_conversation()
        self.assertIsInstance(result, bool)

    def test_get_system_status_shape(self):
        status = self.client.get_system_status()
        self.assertIn("tools", status)
        self.assertIn("skills", status)
        self.assertIn("runtime", status)
        self.assertIn("llm_provider", status)
        self.assertIsInstance(status["tools"], list)
        self.assertEqual(len(status["tools"]), 10)

    def test_no_pending_approval_initially(self):
        self.client.clear_approval_request()
        result = self.client.get_pending_approval_request()
        self.assertIsNone(result)

    def test_set_and_get_pending_approval(self):
        self.client.set_pending_approval_request("rm -rf /tmp/test", "Recursive removal")
        req = self.client.get_pending_approval_request()
        self.assertIsNotNone(req)
        self.assertEqual(req["decision"], "pending")
        self.client.clear_approval_request()

    def test_submit_approval_approved(self):
        ok = self.client.submit_approval_decision("ls /tmp", "Safe listing", "approved")
        self.assertTrue(ok)
        req = self.client.get_pending_approval_request()
        # Should be None because decision was set
        self.assertIsNone(req)
        self.client.clear_approval_request()

    def test_submit_approval_denied(self):
        self.client.set_pending_approval_request("rm -rf /tmp/x", "Dangerous")
        ok = self.client.submit_approval_decision("rm -rf /tmp/x", "Dangerous", "denied")
        self.assertTrue(ok)
        self.client.clear_approval_request()

    def test_invalid_approval_decision_rejected(self):
        ok = self.client.submit_approval_decision("ls", "", "auto_approved_by_model")
        self.assertFalse(ok)

    def test_clarification_state_initially_false(self):
        self.client.clear_conversation()
        result = self.client.is_awaiting_clarification()
        self.assertFalse(result)

    def test_audit_log_path_accessible(self):
        lines = self.client.get_recent_audit_log(5)
        self.assertIsInstance(lines, list)


@unittest.skipIf(SKIP_LIVE, SKIP_REASON)
class TestUIRuntimeIntegration(unittest.TestCase):
    """
    Live integration tests: require PeTTa + API key.
    Skipped automatically without credentials.
    """

    @classmethod
    def setUpClass(cls):
        cls.client = PeTTAAgentClient()
        cls.client.clear_conversation()

    def test_live_simple_query_with_telemetry_stream(self):
        query = "What is the capital of France?"
        events = []
        final_result = None

        stream = self.client.execute_query_stream(query, timeout_seconds=90)
        for item in stream:
            if isinstance(item, AgentEvent):
                events.append(item)
            elif isinstance(item, AgentExecutionResult):
                final_result = item

        self.assertTrue(len(events) >= 3, f"Expected ≥3 events, got {len(events)}")
        event_types = [ev.event_type for ev in events]
        self.assertIn("query_received", event_types)
        self.assertIsNotNone(final_result)
        self.assertTrue(final_result.is_success)
        self.assertIn("Paris", final_result.content)

    def test_live_tool_execution_with_telemetry(self):
        query = "Calculate 25 multiplied by 4."
        events = []
        final_result = None

        stream = self.client.execute_query_stream(query, timeout_seconds=90)
        for item in stream:
            if isinstance(item, AgentEvent):
                events.append(item)
            elif isinstance(item, AgentExecutionResult):
                final_result = item

        self.assertTrue(len(events) >= 4)
        self.assertIsNotNone(final_result)

    def test_conversation_context_preservation(self):
        """Two sequential queries in one session — second should reference first."""
        self.client.clear_conversation()

        queries = ["My name is EvaluatorBot.", "What is my name?"]
        results = []
        for q in queries:
            stream = self.client.execute_query_stream(q, timeout_seconds=90)
            for item in stream:
                if isinstance(item, AgentExecutionResult):
                    results.append(item)

        self.assertEqual(len(results), 2)
        self.assertIn("EvaluatorBot", results[1].content)
