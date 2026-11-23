"""
STAGE D - MILESTONE 13: Event Protocol & Data Models
File: ui/event_protocol.py
Observational telemetry and session data representation (no agent decision logic).
"""

from dataclasses import dataclass, field
from typing import List, Dict, Any, Optional
import time
import re


STAGE_ICONS = {
    "init": "📥",
    "reasoning": "🧠",
    "llm": "🌐",
    "tool": "🛠️",
    "skill": "⚡",
    "planning": "📋",
    "execution": "⚙️",
    "recovery": "🔄",
    "verification": "🔍",
    "memory": "💾",
    "adaptation": "🎯",
    "action": "✨",
    "complete": "✅",
    "error": "❌",
    "feedback": "💬"
}


def mask_sensitive_content(text: str) -> str:
    """Mask potential API keys or sensitive values from user display."""
    if not isinstance(text, str):
        text = str(text)
    # Mask Gemini / OpenAI style API keys (e.g. AIza..., sk-...)
    text = re.sub(r'AIza[0-9A-Za-z\-_]{30,}', '[API_KEY_MASKED]', text)
    text = re.sub(r'sk-[a-zA-Z0-9_\-]{20,}', '[API_KEY_MASKED]', text)
    return text


@dataclass
class AgentEvent:
    timestamp: float
    event_type: str
    stage: str
    message: str
    details: str = ""

    @property
    def icon(self) -> str:
        return STAGE_ICONS.get(self.stage.lower(), "🔹")

    @property
    def formatted_time(self) -> str:
        try:
            return time.strftime("%H:%M:%S", time.localtime(self.timestamp))
        except Exception:
            return ""

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "AgentEvent":
        return cls(
            timestamp=float(data.get("timestamp", time.time())),
            event_type=str(data.get("event_type", "event")),
            stage=str(data.get("stage", "info")),
            message=mask_sensitive_content(str(data.get("message", ""))),
            details=mask_sensitive_content(str(data.get("details", "")))
        )


@dataclass
class PlanTaskItem:
    task_id: str
    task_type: str  # "tool" or "skill"
    name: str
    args: str
    deps: List[str]
    status: str = "pending"  # pending, ready, running, completed, failed, blocked, skipped
    result: str = ""


@dataclass
class AgentExecutionResult:
    status: str  # "success" or "error"
    action: str  # "answer", "finish", "ask_user", "error", etc.
    content: str
    timestamp: float = field(default_factory=time.time)
    events: List[AgentEvent] = field(default_factory=list)
    tasks: List[PlanTaskItem] = field(default_factory=list)

    @property
    def is_success(self) -> bool:
        return self.status == "success"

    @property
    def masked_content(self) -> str:
        return mask_sensitive_content(self.content)


def extract_plan_tasks_from_events(events: List[AgentEvent]) -> List[PlanTaskItem]:
    """Reconstruct task states from real execution telemetry events."""
    task_map: Dict[str, PlanTaskItem] = {}

    for ev in events:
        # Check task started event
        if ev.event_type == "task_started":
            # details: string_concat name args
            m = re.search(r'Executing plan task:\s*(\w+)', ev.message)
            tid = m.group(1) if m else ""
            if tid:
                if tid not in task_map:
                    task_map[tid] = PlanTaskItem(
                        task_id=tid,
                        task_type="tool",
                        name=ev.details.split()[0] if ev.details else "task",
                        args=" ".join(ev.details.split()[1:]) if ev.details else "",
                        deps=[],
                        status="running"
                    )
                else:
                    task_map[tid].status = "running"

        elif ev.event_type == "task_completed":
            m = re.search(r'Task completed:\s*(\w+)', ev.message)
            tid = m.group(1) if m else ""
            if tid and tid in task_map:
                task_map[tid].status = "completed"
                task_map[tid].result = ev.details
            elif tid:
                task_map[tid] = PlanTaskItem(
                    task_id=tid,
                    task_type="tool",
                    name="task",
                    args="",
                    deps=[],
                    status="completed",
                    result=ev.details
                )

        elif ev.event_type == "task_failed":
            m = re.search(r'Task failed:\s*(\w+)', ev.message)
            tid = m.group(1) if m else ""
            if tid and tid in task_map:
                task_map[tid].status = "failed"
                task_map[tid].result = ev.details

    return list(task_map.values())
