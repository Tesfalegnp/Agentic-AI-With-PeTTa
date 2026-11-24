"""
STAGE D - MILESTONE 13: PeTTa Agent Client Adapter
File: ui/agent_client.py
Thin client adapter communicating with the actual PeTTa runtime via controlled files and subprocess telemetry.
"""

import os
import sys
import json
import time
import subprocess
from pathlib import Path
from typing import Generator, List, Dict, Any, Optional

from ui.event_protocol import (
    AgentEvent,
    AgentExecutionResult,
    extract_plan_tasks_from_events,
    mask_sensitive_content
)


class PeTTAAgentClient:
    """
    Thin, safe adapter for executing queries through the real PeTTa Agent runtime.
    Strictly handles IPC, file transport, and telemetry streaming.
    No agent logic or decisions reside here.
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
        self.gateway_script = self.workspace_dir / "agent" / "ui_gateway.metta"
        self.feedback_script = self.workspace_dir / "agent" / "feedback_gateway.metta"
        self.gateway_log_file = self.memory_dir / "gateway_stdout.log"

        # Locate petta executable
        self.petta_bin = os.environ.get("PETTA_BIN", "/home/hope/.local/bin/petta")
        if not os.path.exists(self.petta_bin):
            self.petta_bin = "petta"

        self.memory_dir.mkdir(parents=True, exist_ok=True)

    def execute_query_stream(
        self, query: str, timeout_seconds: int = 120
    ) -> Generator[AgentEvent, None, AgentExecutionResult]:
        """
        Executes user query through PeTTa, streaming live telemetry events as they happen,
        and finally returning the AgentExecutionResult.
        """
        # 1. Clean previous run artifacts
        if self.events_file.exists():
            self.events_file.write_text("", encoding="utf-8")
        if self.result_file.exists():
            try:
                self.result_file.unlink()
            except OSError:
                pass

        # 2. Write query safely to file (immune to shell escaping/injection)
        self.query_file.write_text(query, encoding="utf-8")

        # 3. Spawn PeTTa process redirecting stdout/stderr to gateway log to avoid pipe buffer deadlocks
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

            # 4. Tail events file while process executes
            try:
                while process.poll() is None:
                    if time.time() - start_time > timeout_seconds:
                        process.terminate()
                        timeout_ev = AgentEvent(
                            timestamp=time.time(),
                            event_type="timeout_error",
                            stage="error",
                            message=f"PeTTa execution timed out after {timeout_seconds} seconds.",
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

                # Flush any final events remaining in file after process exit
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
                    message=f"Subprocess communication error: {str(e)}",
                    details=""
                )
                all_events.append(err_ev)
                yield err_ev

        # 5. Retrieve final execution result
        result_status = "error"
        action = "error"
        content = "Agent execution did not produce a final result."

        if self.result_file.exists():
            try:
                res_data = json.loads(self.result_file.read_text(encoding="utf-8"))
                result_status = res_data.get("status", "success")
                action = res_data.get("action", "answer")
                content = res_data.get("content", "")
            except Exception as e:
                content = f"Failed to parse agent result: {str(e)}"
        else:
            # If no result file, check process return code and log
            if process.returncode != 0:
                log_tail = ""
                if self.gateway_log_file.exists():
                    try:
                        log_tail = self.gateway_log_file.read_text(encoding="utf-8", errors="replace")[-1000:]
                    except Exception:
                        pass
                content = f"PeTTa runtime exited with code {process.returncode}.\n{log_tail.strip()}"
            elif all_events:
                # Look for response_final event
                final_ev = next((ev for ev in reversed(all_events) if ev.event_type == "response_final"), None)
                if final_ev:
                    result_status = "success"
                    action = "answer"
                    content = final_ev.details if final_ev.details else final_ev.message
                    content = final_ev.details if final_ev.details else final_ev.message

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

    def submit_feedback(
        self,
        category: str,
        polarity: str,
        text: str,
        target_type: str = "answer",
        target_id: str = "none",
        rating: float = 1.0
    ) -> Dict[str, Any]:
        """Submits feedback directly into PeTTa feedback gateway."""
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
            return {
                "success": False,
                "message": f"Feedback error: {str(e)}",
                "details": ""
            }

    def clear_conversation(self) -> bool:
        """Clears session conversation state and events."""
        try:
            if self.conversation_file.exists():
                self.conversation_file.write_text("", encoding="utf-8")
            if self.events_file.exists():
                self.events_file.write_text("", encoding="utf-8")
            if self.result_file.exists():
                self.result_file.unlink()
            return True
        except Exception:
            return False

    def get_system_status(self) -> Dict[str, Any]:
        """Reads configuration and status without exposing credentials."""
        # 1. Configured provider and model from python_bridge
        provider = os.environ.get("LLM_PROVIDER", "gemini")
        model = os.environ.get("GEMINI_MODEL", "gemini-2.5-flash")
        if provider == "openai":
            model = os.environ.get("OPENAI_MODEL", "gpt-4o-mini")
        elif provider == "deepseek":
            model = os.environ.get("DEEPSEEK_MODEL", "deepseek-chat")

        # 2. Registered tools and skills
        tools = [
            {"name": "calculator", "description": "Mathematical expression evaluator", "category": "math"},
            {"name": "word_counter", "description": "Counts words and tokens in text", "category": "text"},
            {"name": "text_analyzer", "description": "Computes readability and structural metrics", "category": "text"},
            {"name": "string_reverser", "description": "Reverses strings character-by-character", "category": "text"},
            {"name": "datetime", "description": "Retrieves current system UTC/local time", "category": "system"},
            {"name": "read_file", "description": "Reads text content from file safely", "category": "system"},
            {"name": "write_file", "description": "Writes text content to file safely", "category": "system"},
            {"name": "run_command", "description": "Runs shell command with timeout and safety checks", "category": "system"},
            {"name": "send_message", "description": "Sends unbuffered direct message to user", "category": "system"},
            {"name": "web_search", "description": "Searches the web for current facts, options, and documentation", "category": "research"}
        ]

        skills = [
            {"name": "math_skill", "description": "Two-step calculation & numeric verification", "steps": 2},
            {"name": "text_process_skill", "description": "Multi-step text analysis & summary pipeline", "steps": 2},
            {"name": "research_skill", "description": "Query decomposition and memory retrieval pipeline", "steps": 2}
        ]

        # 3. Persistent Memory Counts
        long_term_file = self.workspace_dir / "memory" / "long_term" / "long_term_store.data"
        long_term_count = 0
        if long_term_file.exists():
            try:
                lines = [l for l in long_term_file.read_text(encoding="utf-8").splitlines() if l.strip()]
                long_term_count = len(lines)
            except Exception:
                pass

        # 4. Active Adaptation Rules Count
        adaptation_file = self.memory_dir / "adaptation_rules.tsv"
        adaptation_count = 0
        active_adaptations = []
        if adaptation_file.exists():
            try:
                lines = [l for l in adaptation_file.read_text(encoding="utf-8").splitlines() if l.strip()]
                for l in lines[1:]:  # Skip header
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

        return {
            "framework": "PeTTa Agentic AI Framework",
            "runtime": "PeTTa 2.0 (SWI-Prolog Engine)",
            "llm_provider": provider.capitalize(),
            "configured_model": model,
            "status": "Ready",
            "tools": tools,
            "skills": skills,
            "memory_records_count": long_term_count,
            "active_adaptations_count": adaptation_count,
            "active_adaptations": active_adaptations
        }
