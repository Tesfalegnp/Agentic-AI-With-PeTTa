"""
Import and render tests for UI app components.
File: tests/ui/test_ui_app_import.py
"""

import unittest
import importlib


class TestUIAppImport(unittest.TestCase):

    def test_styles_import(self):
        import ui.styles as styles
        self.assertTrue(hasattr(styles, "CUSTOM_CSS"))
        self.assertIn("main-header", styles.CUSTOM_CSS)
        self.assertIn("task-card", styles.CUSTOM_CSS)
        self.assertIn("stSidebar", styles.CUSTOM_CSS)
        self.assertIn("stExpander", styles.CUSTOM_CSS)
        self.assertIn("stExpanderDetails", styles.CUSTOM_CSS)

    def test_event_protocol_import(self):
        import ui.event_protocol as proto
        self.assertTrue(hasattr(proto, "AgentEvent"))
        self.assertTrue(hasattr(proto, "AgentExecutionResult"))
        self.assertTrue(hasattr(proto, "STAGE_ICONS"))

    def test_agent_client_import(self):
        import ui.agent_client as client_mod
        self.assertTrue(hasattr(client_mod, "PeTTAAgentClient"))


if __name__ == "__main__":
    unittest.main()
