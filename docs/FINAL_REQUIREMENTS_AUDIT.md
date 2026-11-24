# Comprehensive Requirements Gap Analysis & Audit Matrix

**Project Workspace:** `/home/hope/Projects/petta-agentic-ai`  
**PeTTa Upstream Runtime:** `/home/hope/Projects/PeTTa`  
**Date:** 2026-11-24  
**Audit Stage:** Phase 1 Complete

---

## 1. Executive Assessment

A full, ground-truth inspection was performed across all source files, Prolog modules, Python bridge components, test suites, and git repository state:

1. **PeTTa Architecture & Engine Health:**
   - The upstream PeTTa installation at `/home/hope/Projects/PeTTa` is complete and functional.
   - All 61 automated PeTTa subsystem test files (`tests/**/*.metta`) pass (100% PASS, 61/61).
   - All 35 Python bridge unit tests (`tests/test_bridge_python.py`, `tests/test_multi_provider_python.py`) pass (100% PASS, 35/35).
   - Total regression test suites currently passing: **96 automated test suites**.

2. **Core Architectural Purity:**
   - PeTTa owns the cognitive loop (`agent/loop.metta`), goal planning (`agent/goal_planner.metta`), DAG task scheduling (`agent/task_scheduler.metta`), plan execution (`agent/plan_executor.metta`), plan verification (`agent/plan_verifier.metta`), AtomSpace memory (`agent/memory_core.metta`), and adaptive learning (`agent/adaptation_engine.metta`).
   - Python is strictly confined to stateless API transport (`python_bridge/bridge.py`) and Streamlit presentation (`ui/app.py`).

3. **Critical Identified Gaps:**
   - **Mandatory Tool Set Discrepancy:** The assignment explicitly mandates five tools:
     1. `read_file`: Read a file safely.
     2. `write_file`: Write a file safely.
     3. `run_command`: Run a shell command with timeout and destructive operation confirmation.
     4. `send_message`: Send an unbuffered message/notification to the user.
     5. `ask_user`: Interactive clarification questioning mechanism.
     *Current Status:* The framework currently only has `calculator`, `word_counter`, `text_analyzer`, `string_reverser`, and `datetime`. The 5 mandatory system tools are **MISSING** from the tool registry.
   - **Unified Shared CLI / UI Session Runtime:**
     - The CLI in `agent/controller.metta` uses terminal `readln!` and an in-memory loop, while the Streamlit UI uses `agent/ui_gateway.metta` with file-based IPC and JSONL telemetry. They must share identical state management and session continuity.
   - **Long-Running Task Execution (20+ Turns):**
     - Current `cognitive-step` hardcodes `max_iterations = 5` and plan executor loop hardcodes 15. The prompt context manager trims context at 16,000 characters, but lacks proactive tool output truncation for arbitrarily large file reads or command outputs. Needs configurable turn budgets supporting 20–50+ turns with stuck-state detection.
   - **Shell Command Safety Guardrails:**
     - Needs destructive command detection (e.g. `rm -rf`, `mkfs`, overwrite patterns) requiring explicit confirmation before execution, configurable timeout, and protection against command injection.

---

## 2. Detailed Requirement Traceability Table

| Requirement ID | Requirement Description | Existing Implementation | Evidence / File | Test Evidence | Status | Required Action |
|---|---|---|---|---|---|---|
| **A.1** | Agent in MeTTa/PeTTa runs locally and completes user tasks | PeTTa cognitive loop, action validator, prompt engine | `agent/loop.metta`<br>`agent/action_validator.metta` | 61 Metta tests passing | **PASS** | Maintain strict PeTTa ownership |
| **A.2** | Usable CLI where a user can enter tasks | Interactive loop in `agent/controller.metta` via `readln!` | `agent/controller.metta`<br>`main.metta` | Manual execution verified | **PASS** | Align CLI with gateway IPC & telemetry |
| **A.3** | Keep agent process running between tasks without restarting | Interactive chat loop recursion in `controller.metta` | `agent/controller.metta` | `test_state.metta` | **PASS** | Verify persistent state across sequential turns |
| **A.4** | CLI and UI use same underlying PeTTa agent runtime | Both invoke `run-cognitive-cycle` from `agent/loop.metta` | `agent/controller.metta`<br>`agent/ui_gateway.metta` | `test_agent_client.py` | **PASS** | Unify telemetry emission for CLI sessions |
| **A.5** | Session continuity without losing active goal | Working memory in `&conversation` and `&goal_space` | `agent/state.metta`<br>`agent/goal_manager.metta` | `test_ui_runtime_integration.py` | **PASS** | Ensure cross-turn goal persistence |
| **B.1** | Tool: Read a file (`read_file`) | Missing from tool registry and primitives | None | Missing | **FAIL** | Implement Prolog helper `read_file_safe/3`, register in `agent/tool_registry.metta`, add dispatcher binding |
| **B.2** | Tool: Write a file (`write_file`) | Missing from tool registry and primitives | None | Missing | **FAIL** | Implement Prolog helper `write_file_safe/3`, register in `agent/tool_registry.metta`, add dispatcher binding |
| **B.3** | Tool: Run shell command (`run_command`) with timeout & safety | Missing from tool registry and primitives | None | Missing | **FAIL** | Implement Prolog helper `execute_shell_command_safe/4` with timeout, destructive operation approval check, input sanitization |
| **B.4** | Tool: Send message to user (`send_message`) | Handled via canonical `answer` or raw print | Missing as formal tool | Missing | **PARTIAL** | Register `send_message` tool in registry and dispatcher |
| **B.5** | Tool: Ask user a question (`ask_user`) | Implemented as canonical action `(action ask_user "...")` | `agent/action_validator.metta`<br>`agent/loop.metta` | `test_parser_validator.metta` | **PASS** | Also expose as `use_tool ask_user` for planning consistency |
| **B.6** | Tool error handling as readable observations without crashing | Tool dispatcher wraps errors in `ToolResult failure` | `agent/tool_dispatcher.metta`<br>`agent/tool_result.metta` | `test_tool_dispatcher.metta` | **PASS** | Extend to file I/O and shell execution |
| **B.7** | Unknown tool rejection | Rejected by `tool_validator.metta` | `agent/tool_validator.metta` | `test_tool_validator.metta` | **PASS** | Verified |
| **B.8** | Tool call audit history | Recorded in `&tool_history` AtomSpace | `agent/tool_history.metta` | `test_tool_history.metta` | **PASS** | Verified |
| **C.1** | Complete 10-step execution cycle | Full cognitive cycle with planning check | `agent/loop.metta` | `test_tool_agent_loop.metta` | **PASS** | Verified |
| **C.2** | Canonical Eight-Action Protocol | Exact grammar matching for all 8 actions | `agent/action_validator.metta` | `test_action_parsing.metta` | **PASS** | Verified |
| **D.1** | Long-running tasks for 20+ turns | Loop limit currently set to 5/15 turns | `agent/loop.metta`<br>`agent/plan_executor.metta` | None > 15 turns | **PARTIAL** | Support configurable iteration limit up to 30+ turns with progress tracking |
| **D.2** | Truncation of large tool outputs | Truncation helper in Prolog budget engine | `agent/context_budget.metta` | `test_memory_context_budget.metta` | **PARTIAL** | Explicitly bound tool output observation strings to 2000 chars to avoid prompt bloat |
| **D.3** | Stuck-state detection & loop prevention | Repetition detection absent in loop recursion | `agent/loop.metta` | Missing | **PARTIAL** | Add action hash/fingerprint history in `&conversation` to detect repeated identical tool calls |
| **E.1** | Failure recovery and replanning | Plan recovery budget in `plan_recovery.metta` | `agent/plan_recovery.metta` | `test_plan_recovery.metta` | **PASS** | Verified |
| **E.2** | Clarification on missing parameters | Triggers `(action ask_user ...)` | `agent/action_validator.metta` | `test_parser_validator.metta` | **PASS** | Verified |
| **F.1** | Advanced DAG Planning & Recovery | Full DAG topological sorting and execution | `agent/goal_planner.metta`<br>`agent/task_scheduler.metta` | 9 planning unit tests passing | **PASS** | Verified |
| **F.2** | Persistent AtomSpace Memory | 5 categories, disk storage, ranking | `agent/memory_core.metta` | 15 memory tests passing | **PASS** | Verified |
| **F.3** | Adaptive Learning & Feedback | User feedback recording, rule synthesis | `agent/adaptation_engine.metta` | 10 adaptation tests passing | **PASS** | Verified |
| **F.4** | Streamlit UI & Real Telemetry | Unbuffered JSONL telemetry streaming, DAG cards | `ui/app.py`<br>`agent/telemetry_io.pl` | `test_ui_models.py` | **PASS** | Verified |

---

## 3. Targeted Implementation Plan (Phase 2)

1. **Implement Safe System Tools in SWI-Prolog Helper (`tools/system_primitives.pl`):**
   - `read_file_safe(+Path, -ContentStr)`: Checks path traversal, validates file existence, UTF-8 reading, max size bounding.
   - `write_file_safe(+Path, +ContentStr, -Status)`: Creates parent directory, writes content with UTF-8 encoding.
   - `execute_shell_command_safe(+Command, +TimeoutSec, +Approved, -OutputStr)`: Checks against dangerous command patterns (`rm -rf`, `mkfs`, `dd`, `shutdown`). Requires `Approved=true` for destructive commands. Runs command with `process_create/3` and timeout.
   - `send_user_message(+Msg, -Status)`: Writes message to unbuffered telemetry stream and output.

2. **Register Mandatory Tools in PeTTa (`agent/tool_registry.metta`):**
   - Register `read_file`, `write_file`, `run_command`, `send_message`, `ask_user`.
   - Update `agent/tool_validator.metta` with schemas for the 5 tools.
   - Bind execution in `agent/tool_dispatcher.metta` to call the Prolog primitives.

3. **Enhance Cognitive Loop for 20+ Turn Long-Running Tasks (`agent/loop.metta`):**
   - Increase default turn limit to 25 turns for complex multi-step tasks.
   - Add duplicate action/loop detection in working memory.
   - Add tool observation truncation (bound to 2000 chars) before feeding back into prompt.

4. **Synchronize CLI with Session IPC & Telemetry (`agent/controller.metta`):**
   - Provide clean CLI runner supporting continuous multi-task execution in one session with exit commands (`exit`, `quit`).
