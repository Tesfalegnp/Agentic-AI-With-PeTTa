"""
Unit tests for UI event protocol and data models.
File: tests/ui/test_ui_models.py
"""

import unittest
import time
from ui.event_protocol import (
    AgentEvent,
    PlanTaskItem,
    AgentExecutionResult,
    mask_sensitive_content,
    extract_plan_tasks_from_events,
    STAGE_ICONS
)


class TestUIModels(unittest.TestCase):

    def test_agent_event_creation_and_properties(self):
        ev = AgentEvent(
            timestamp=1700000000.0,
            event_type="test_event",
            stage="tool",
            message="Dispatching tool calculator",
            details="25 * 4"
        )
        self.assertEqual(ev.event_type, "test_event")
        self.assertEqual(ev.stage, "tool")
        self.assertEqual(ev.icon, "🛠️")
        self.assertIn("Dispatching tool", ev.message)
        self.assertTrue(len(ev.formatted_time) > 0)

    def test_agent_event_from_dict(self):
        raw = {
            "timestamp": 1700000100.0,
            "event_type": "goal_created",
            "stage": "planning",
            "message": "Created goal g_1",
            "details": "Analyze text"
        }
        ev = AgentEvent.from_dict(raw)
        self.assertEqual(ev.event_type, "goal_created")
        self.assertEqual(ev.stage, "planning")
        self.assertEqual(ev.icon, "📋")
        self.assertEqual(ev.message, "Created goal g_1")

    def test_mask_sensitive_content(self):
        gemini_key = "AIzaSyD-exampleKey1234567890123456789"
        openai_key = "sk-proj-exampleKey1234567890abcdef123456"
        plain_text = f"Using key {gemini_key} and {openai_key} in request."

        masked = mask_sensitive_content(plain_text)
        self.assertNotIn(gemini_key, masked)
        self.assertNotIn(openai_key, masked)
        self.assertIn("[API_KEY_MASKED]", masked)

    def test_extract_plan_tasks_from_events(self):
        events = [
            AgentEvent(
                timestamp=time.time(),
                event_type="task_started",
                stage="execution",
                message="Executing plan task: t1",
                details="word_counter Text Analysis"
            ),
            AgentEvent(
                timestamp=time.time() + 1,
                event_type="task_completed",
                stage="execution",
                message="Task completed: t1",
                details="2"
            ),
            AgentEvent(
                timestamp=time.time() + 2,
                event_type="task_started",
                stage="execution",
                message="Executing plan task: t2",
                details="calculator 50 * 2"
            ),
            AgentEvent(
                timestamp=time.time() + 3,
                event_type="task_failed",
                stage="recovery",
                message="Task failed: t2",
                details="Division by zero"
            )
        ]

        tasks = extract_plan_tasks_from_events(events)
        self.assertEqual(len(tasks), 2)

        t1 = next(t for t in tasks if t.task_id == "t1")
        self.assertEqual(t1.status, "completed")
        self.assertEqual(t1.result, "2")

        t2 = next(t for t in tasks if t.task_id == "t2")
        self.assertEqual(t2.status, "failed")
        self.assertEqual(t2.result, "Division by zero")

    def test_execution_result_properties(self):
        res = AgentExecutionResult(
            status="success",
            action="answer",
            content="Paris is the capital of France.",
            timestamp=time.time()
        )
        self.assertTrue(res.is_success)
        self.assertEqual(res.action, "answer")
        self.assertIn("Paris", res.masked_content)


if __name__ == "__main__":
    unittest.main()
