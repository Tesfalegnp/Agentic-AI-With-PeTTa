"""
PeTTa Agentic AI Framework — Agent Client Adapter (Competition Edition)
File: ui/agent_client.py

Thin IPC adapter. All agent intelligence lives in PeTTa.
Adds:
  - Human approval IPC for destructive shell commands
  - Approval panel state management
  - Clarification state detection
  - Audit log reading for transparency
"""

import os
import sys
import json
import time
import subprocess
import hashlib
from pathlib import Path
from typing import Generator, List, Dict, Any, Optional
from dotenv import load_dotenv

from ui.event_protocol import (
    AgentEvent,
    AgentExecutionResult,
    extract_plan_tasks_from_events,
    mask_sensitive_content
)


class PeTTAAgentClient:
    """
    Thin, safe adapter for executing queries through the real PeTTa Agent runtime.
    No agent logic lives here — only IPC, file transport, telemetry streaming,
    and the human approval gateway.
    """

    def __init__(self, workspace_dir: Optional[str] = None):
        if workspace_dir:
            self.workspace_dir = Path(workspace_dir)
        else:
            self.workspace_dir = Path(__file__).resolve().parent.parent

        self.memory_dir = self.workspace_dir / "memory"
        self.query_file = self.memory_dir / "session_query.txt"
        self.events_file = self.memory_dir / "session_events.jsonl"
        self.result_file = self.memory_dir / "session_result.json"
        self.feedback_file = self.memory_dir / "session_feedback.json"
        self.conversation_file = self.memory_dir / "session_conversation.tsv"
        self.approval_file = self.memory_dir / "pending_approval.json"
        self.audit_log_file = self.workspace_dir / "logs" / "command_audit.log"
        self.gateway_script = self.workspace_dir / "agent" / "ui_gateway.metta"
        self.feedback_script = self.workspace_dir / "agent" / "feedback_gateway.metta"
        self.gateway_log_file = self.memory_dir / "gateway_stdout.log"

        # Locate petta executable
        self.petta_bin = os.environ.get("PETTA_BIN", "/home/hope/.local/bin/petta")
        if not os.path.exists(self.petta_bin):
            self.petta_bin = "petta"

        self.memory_dir.mkdir(parents=True, exist_ok=True)
        (self.workspace_dir / "logs").mkdir(parents=True, exist_ok=True)
        load_dotenv(self.workspace_dir / ".env")

    # =========================================================================
    # Core Execution Stream
    # =========================================================================

    def execute_query_stream(
        self, query: str, timeout_seconds: int = 120
    ) -> Generator[AgentEvent, None, AgentExecutionResult]:
        """
        Executes user query through PeTTa, streaming live telemetry events.
        Returns AgentExecutionResult at end of stream.
        """
        # 1. Clean previous run artifacts
        if self.events_file.exists():
            self.events_file.write_text("", encoding="utf-8")
        if self.result_file.exists():
            try:
                self.result_file.unlink()
            except OSError:
                pass

        # 2. Write query safely (immune to shell injection)
        self.query_file.write_text(query, encoding="utf-8")

        # 3. Spawn PeTTa process
        cmd = [self.petta_bin, str(self.gateway_script)]
        env = os.environ.copy()
        env["PYTHONUNBUFFERED"] = "1"

        all_events: List[AgentEvent] = []
        read_offset = 0
        start_time = time.time()

        with open(self.gateway_log_file, "w", encoding="utf-8") as gateway_log:
            process = subprocess.Popen(
                cmd,
                cwd=str(self.workspace_dir),
                stdout=gateway_log,
                stderr=subprocess.STDOUT,
                env=env
            )

            try:
                while process.poll() is None:
                    if time.time() - start_time > timeout_seconds:
                        process.terminate()
                        timeout_ev = AgentEvent(
                            timestamp=time.time(),
                            event_type="timeout_error",
                            stage="error",
                            message=f"PeTTa execution timed out after {timeout_seconds}s.",
                            details=""
                        )
                        all_events.append(timeout_ev)
                        yield timeout_ev
                        break

                    if self.events_file.exists():
                        with open(self.events_file, "r", encoding="utf-8") as f:
                            f.seek(read_offset)
                            new_lines = f.readlines()
                            read_offset = f.tell()

                        for line in new_lines:
                            line = line.strip()
                            if line:
                                try:
                                    data = json.loads(line)
                                    ev = AgentEvent.from_dict(data)
                                    all_events.append(ev)
                                    yield ev
                                except json.JSONDecodeError:
                                    pass

                    time.sleep(0.1)

                # Flush remaining events after process exit
                if self.events_file.exists():
                    with open(self.events_file, "r", encoding="utf-8") as f:
                        f.seek(read_offset)
                        final_lines = f.readlines()
                    for line in final_lines:
                        line = line.strip()
                        if line:
                            try:
                                data = json.loads(line)
                                ev = AgentEvent.from_dict(data)
                                all_events.append(ev)
                                yield ev
                            except json.JSONDecodeError:
                                pass

            except Exception as e:
                err_ev = AgentEvent(
                    timestamp=time.time(),
                    event_type="client_error",
                    stage="error",
                    message=f"Subprocess error: {mask_sensitive_content(str(e))}",
                    details=""
                )
                all_events.append(err_ev)
                yield err_ev

        # 4. Retrieve final result
        result_status = "error"
        action = "error"
        content = "Agent execution did not produce a final result."

        if self.result_file.exists():
            try:
                res_data = json.loads(self.result_file.read_text(encoding="utf-8"))
                result_status = res_data.get("status", "success")
                action = res_data.get("action", "answer")
                content = mask_sensitive_content(res_data.get("content", ""))
            except Exception as e:
                content = f"Failed to parse agent result: {str(e)}"
        else:
            if process.returncode != 0:
                log_tail = ""
                if self.gateway_log_file.exists():
                    try:
                        log_tail = self.gateway_log_file.read_text(
                            encoding="utf-8", errors="replace"
                        )[-1500:]
                    except Exception:
                        pass
                content = mask_sensitive_content(
                    f"PeTTa exited with code {process.returncode}.\n{log_tail.strip()}"
                )
            elif all_events:
                final_ev = next(
                    (ev for ev in reversed(all_events) if ev.event_type == "response_final"),
                    None
                )
                if final_ev:
                    result_status = "success"
                    action = "answer"
                    content = mask_sensitive_content(
                        final_ev.details if final_ev.details else final_ev.message
                    )

        tasks = extract_plan_tasks_from_events(all_events)
        final_res = AgentExecutionResult(
            status=result_status,
            action=action,
            content=content,
            timestamp=time.time(),
            events=all_events,
            tasks=tasks
        )
        yield final_res
        return final_res

    # =========================================================================
    # Human Approval Gateway (Destructive Command Security)
    # =========================================================================

    def get_pending_approval_request(self) -> Optional[Dict[str, Any]]:
        """
        Read the pending approval file if it exists and has an unresolved request.
        Returns None if no approval is pending.
        """
        if not self.approval_file.exists():
            return None
        try:
            data = json.loads(self.approval_file.read_text(encoding="utf-8"))
            if data.get("decision") in ("approved", "denied"):
                return None  # Already decided
            return data
        except Exception:
            return None

    def submit_approval_decision(self, command: str, risk: str, decision: str) -> bool:
        """
        Write human approval decision to the IPC file.
        Only 'approved' or 'denied' are valid decisions.
        Returns True if written successfully.

        SECURITY: This is the ONLY path through which approval reaches the agent.
        The model cannot write to this file.
        """
        if decision not in ("approved", "denied"):
            return False

        approval_data = {
            "command": command,
            "risk": risk,
            "decision": decision,
            "timestamp": time.time(),
            "command_fingerprint": hashlib.sha256(command.encode()).hexdigest()[:16]
        }
        try:
            self.approval_file.write_text(
                json.dumps(approval_data, indent=2), encoding="utf-8"
            )
            return True
        except Exception:
            return False

    def clear_approval_request(self) -> None:
        """Remove the approval IPC file after the decision has been acted on."""
        if self.approval_file.exists():
            try:
                self.approval_file.unlink()
            except Exception:
                pass

    def set_pending_approval_request(self, command: str, risk: str) -> bool:
        """
        Create a pending approval request (undecided state).
        Called when the agent detects an APPROVAL_REQUIRED response.
        """
        approval_data = {
            "command": command,
            "risk": risk,
            "decision": "pending",
            "timestamp": time.time(),
            "command_fingerprint": hashlib.sha256(command.encode()).hexdigest()[:16]
        }
        try:
            self.approval_file.write_text(
                json.dumps(approval_data, indent=2), encoding="utf-8"
            )
            return True
        except Exception:
            return False

    # =========================================================================
    # Clarification State Detection
    # =========================================================================

    def is_awaiting_clarification(self) -> bool:
        """Check if the last agent result was an ask_user action."""
        if not self.result_file.exists():
            return False
        try:
            data = json.loads(self.result_file.read_text(encoding="utf-8"))
            return data.get("action") == "ask_user"
        except Exception:
            return False

    def get_clarification_question(self) -> str:
        """Return the clarification question from the last agent result."""
        if not self.result_file.exists():
            return ""
        try:
            data = json.loads(self.result_file.read_text(encoding="utf-8"))
            if data.get("action") == "ask_user":
                return data.get("content", "")
        except Exception:
            pass
        return ""

    # =========================================================================
    # Audit Log
    # =========================================================================

    def get_recent_audit_log(self, max_lines: int = 20) -> List[str]:
        """Read recent command audit log entries."""
        if not self.audit_log_file.exists():
            return []
        try:
            lines = self.audit_log_file.read_text(encoding="utf-8").splitlines()
            return lines[-max_lines:]
        except Exception:
            return []

    # =========================================================================
    # Feedback
    # =========================================================================

    def submit_feedback(
        self,
        category: str,
        polarity: str,
        text: str,
        target_type: str = "answer",
        target_id: str = "none",
        rating: float = 1.0
    ) -> Dict[str, Any]:
        """Submits feedback to PeTTa feedback gateway."""
        feedback_data = {
            "category": category,
            "polarity": polarity,
            "target_type": target_type,
            "target_id": target_id,
            "text": text,
            "rating": rating
        }
        self.feedback_file.write_text(json.dumps(feedback_data), encoding="utf-8")
        cmd = [self.petta_bin, str(self.feedback_script)]
        try:
            res = subprocess.run(
                cmd,
                cwd=str(self.workspace_dir),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=30
            )
            return {
                "success": res.returncode == 0,
                "message": "Feedback recorded in PeTTa AtomSpace.",
                "details": res.stdout.strip()
            }
        except Exception as e:
            return {"success": False, "message": f"Feedback error: {str(e)}", "details": ""}

    # =========================================================================
    # Session Management
    # =========================================================================

    def clear_conversation(self) -> bool:
        """Clear all session state for task isolation."""
        try:
            for f in [self.conversation_file, self.events_file]:
                if f.exists():
                    f.write_text("", encoding="utf-8")
            for f in [self.result_file, self.approval_file]:
                if f.exists():
                    try:
                        f.unlink()
                    except Exception:
                        pass
            return True
        except Exception:
            return False

    # =========================================================================
    # System Status
    # =========================================================================

    def get_system_status(self) -> Dict[str, Any]:
        """Reads configuration and runtime status without exposing credentials."""
        provider = os.environ.get("LLM_PROVIDER", "gemini")
        model = os.environ.get("GEMINI_MODEL", "gemini-2.5-flash")
        if provider == "openai":
            model = os.environ.get("OPENAI_MODEL", "gpt-4o-mini")
        elif provider == "deepseek":
            model = os.environ.get("DEEPSEEK_MODEL", "deepseek-chat")

        # Check API key configured (without revealing it)
        api_key_configured = False
        if provider == "gemini":
            api_key_configured = bool(os.environ.get("GEMINI_API_KEY", ""))
        elif provider == "openai":
            api_key_configured = bool(os.environ.get("OPENAI_API_KEY", ""))
        elif provider == "deepseek":
            api_key_configured = bool(os.environ.get("DEEPSEEK_API_KEY", ""))

        tools = [
            {"name": "calculator",      "description": "Mathematical expression evaluator",           "category": "math"},
            {"name": "word_counter",    "description": "Word and token counter",                      "category": "text"},
            {"name": "text_analyzer",   "description": "Structural text metrics and readability",     "category": "text"},
            {"name": "string_reverser", "description": "String reversal utility",                     "category": "text"},
            {"name": "datetime",        "description": "Current UTC/local timestamp",                  "category": "system"},
            {"name": "read_file",       "description": "Safe bounded text file reader",               "category": "system"},
            {"name": "write_file",      "description": "Safe file writer with path protection",       "category": "system"},
            {"name": "run_command",     "description": "Shell with timeout + human approval gate",    "category": "system"},
            {"name": "send_message",    "description": "Direct user notification message",            "category": "system"},
            {"name": "web_search",      "description": "Live web search (Tavily/Brave/DuckDuckGo)",  "category": "research"},
        ]

        skills = [
            {"name": "math_skill",         "description": "Two-step computation and verification",     "steps": 2},
            {"name": "text_process_skill", "description": "Text analysis and summarization pipeline",  "steps": 2},
            {"name": "research_skill",     "description": "Query decomposition and memory retrieval",  "steps": 2},
        ]

        # Persistent memory counts
        long_term_file = self.workspace_dir / "memory" / "long_term" / "long_term_store.data"
        long_term_count = 0
        if long_term_file.exists():
            try:
                lines = [
                    l for l in long_term_file.read_text(encoding="utf-8").splitlines()
                    if l.strip()
                ]
                long_term_count = len(lines)
            except Exception:
                pass

        # Adaptation rules
        adaptation_file = self.memory_dir / "adaptation_rules.tsv"
        adaptation_count = 0
        active_adaptations = []
        if adaptation_file.exists():
            try:
                lines = [
                    l for l in adaptation_file.read_text(encoding="utf-8").splitlines()
                    if l.strip()
                ]
                for l in lines[1:]:
                    parts = l.split("\t")
                    if len(parts) >= 11 and parts[10] == "active":
                        adaptation_count += 1
                        active_adaptations.append({
                            "id": parts[0],
                            "category": parts[1],
                            "description": parts[2],
                            "recommendation": parts[4]
                        })
            except Exception:
                pass

        # Approval pending?
        pending_approval = self.get_pending_approval_request()

        return {
            "framework": "PeTTa Agentic AI Framework",
            "runtime": "PeTTa (SWI-Prolog + MeTTa Engine)",
            "llm_provider": provider.capitalize(),
            "configured_model": model,
            "api_key_configured": api_key_configured,
            "status": "Ready",
            "tools": tools,
            "skills": skills,
            "memory_records_count": long_term_count,
            "active_adaptations_count": adaptation_count,
            "active_adaptations": active_adaptations,
            "pending_approval": pending_approval,
        }
