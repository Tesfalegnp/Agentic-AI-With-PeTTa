"""
Live runtime integration tests connecting PeTTAAgentClient to the real PeTTa engine.
File: tests/ui/test_ui_runtime_integration.py
"""

import unittest
import time
from ui.agent_client import PeTTAAgentClient
from ui.event_protocol import AgentEvent, AgentExecutionResult


class TestUIRuntimeIntegration(unittest.TestCase):

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

        # Verify real telemetry events were emitted by PeTTa
        self.assertTrue(len(events) >= 3, f"Expected at least 3 events, got {len(events)}")
        event_types = [ev.event_type for ev in events]
        self.assertIn("query_received", event_types)
        self.assertIn("planning_check", event_types)
        self.assertIn("llm_query", event_types)

        # Verify final result returned
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
        event_types = [ev.event_type for ev in events]
        # Should include tool dispatching and completion
        self.assertTrue("tool_dispatching" in event_types or "action_parsed" in event_types)

        self.assertIsNotNone(final_result)
        self.assertTrue(final_result.is_success)
        self.assertTrue("100" in final_result.content)

    def test_conversation_context_preservation(self):
        # Query 1
        q1 = "My favorite color is emerald blue."
        list(self.client.execute_query_stream(q1, timeout_seconds=90))

        # Check conversation session file
        conv_text = self.client.conversation_file.read_text(encoding="utf-8")
        self.assertIn("emerald blue", conv_text)

        # Query 2 asking about previous turn
        q2 = "What is my favorite color?"
        res = None
        for item in self.client.execute_query_stream(q2, timeout_seconds=90):
            if isinstance(item, AgentExecutionResult):
                res = item

        self.assertIsNotNone(res)
        self.assertTrue(res.is_success)
        self.assertTrue("blue" in res.content.lower() or "emerald" in res.content.lower())


if __name__ == "__main__":
    unittest.main()
