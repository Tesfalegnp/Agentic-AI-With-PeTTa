# PeTTa Agentic AI Framework: Testing & Verification Guide

This document details the complete automated test organization, execution procedures, test categories, and baseline verification results for the **PeTTa Agentic AI Framework**.

---

## 1. Test Architecture & Organization

The test suite is structured into two complementary tiers:
1. **PeTTa Subsystem Regression Suite (Headless MeTTa):** 54 deterministic tests validating symbolic reasoning, protocol parsing, tool dispatching, composite skills, long-term memory operations, DAG planning, and adaptive learning directly within the PeTTa runtime.
2. **Python Bridge & UI Test Suite (Python `unittest`):** 35 unit, safety, and integration tests validating provider transport, secret masking, data models, IPC adapter streaming, and live end-to-end execution.

```
tests/
├── protocol/               # Canonical action protocol parsing & syntax validation
│   └── test_action_parsing.metta
├── agent/                  # Core cognitive loop, mocked loops, prompt assembly, state
│   ├── test_loop_mocked.metta
│   ├── test_parser_validator.metta
│   ├── test_prompt.metta
│   └── test_state.metta
├── tools/                  # Tool registry, argument validation, dispatch, built-in tools
│   ├── test_builtin_tools.metta
│   ├── test_tool_dispatcher.metta
│   ├── test_tool_history.metta
│   ├── test_tool_registry.metta
│   └── test_tool_validator.metta
├── skills/                 # Skill registry, workflows, execution, composite skills
│   ├── test_builtin_skills.metta
│   ├── test_skill_agent_loop_mocked.metta
│   ├── test_skill_executor.metta
│   ├── test_skill_history.metta
│   ├── test_skill_registry.metta
│   ├── test_skill_validator.metta
│   └── test_skill_workflow.metta
├── memory/                 # AtomSpace memory, persistence, ranking, consistency, budget
│   ├── persistence_read.metta
│   ├── persistence_write.metta
│   ├── store_episodic.metta
│   ├── store_long_term.metta
│   ├── test_atomspace.metta
│   ├── test_malformed_record_resilience.metta
│   ├── test_memory_agent_loop_mocked.metta
│   ├── test_memory_aware_loop.metta
│   ├── test_memory_consistency.metta
│   ├── test_memory_consolidation.metta
│   ├── test_memory_context_budget.metta
│   ├── test_memory_context_manager.metta
│   ├── test_memory_crud_retrieval.metta
│   ├── test_memory_lifecycle.metta
│   ├── test_memory_persistence_process1.metta
│   ├── test_memory_persistence_process2.metta
│   ├── test_memory_ranking.metta
│   └── test_memory_validator.metta
├── planning/               # Goal management, plan building, DAG scheduling, DAG execution
│   ├── test_goal_manager.metta
│   ├── test_plan_builder.metta
│   ├── test_plan_executor.metta
│   ├── test_plan_history.metta
│   ├── test_plan_recovery.metta
│   ├── test_plan_validator.metta
│   ├── test_plan_verifier.metta
│   ├── test_planning_agent_loop.metta
│   └── test_task_scheduler.metta
├── adaptation/             # Feedback tracking, pattern detection, rule synthesis, lifecycle
│   ├── test_adaptation_conflict.metta
│   ├── test_adaptation_evaluation.metta
│   ├── test_adaptation_history.metta
│   ├── test_adaptation_lifecycle.metta
│   ├── test_adaptation_persistence.metta
│   ├── test_adaptation_prompt_integration.metta
│   ├── test_adaptation_registry.metta
│   ├── test_adaptation_validator.metta
│   ├── test_feedback_aggregation.metta
│   └── test_feedback_store.metta
├── ui/                     # UI data models, secret masking, adapter streaming, live integration
│   ├── test_agent_client.py
│   ├── test_ui_app_import.py
│   ├── test_ui_models.py
│   ├── test_ui_safety.py
│   └── test_ui_runtime_integration.py (Live PeTTa End-to-End)
├── interop/                # Janus py-call & multi-provider transport
│   ├── test_py_interop.metta
│   ├── test_gemini_bridge.metta
│   └── test_multi_provider_bridge.metta
└── integration/            # Full live agent execution scripts
    ├── test_live_agent.metta
    ├── test_tool_agent_loop.metta
    ├── test_skill_agent_loop.metta
    ├── test_memory_aware_live.metta
    ├── test_planning_live.metta
    └── test_adaptation_live.metta
```

---

## 2. Test Execution Commands

### 2.1. Python Unit & Bridge Tests
Run all Python-level unit tests via `unittest` discovery:
```bash
.venv/bin/python3 -m unittest discover tests/
```
*Expected Result:*
```
...................................
----------------------------------------------------------------------
Ran 35 tests in 0.025s

OK
```

### 2.2. PeTTa Subsystem Regression Suite (54 Tests)
Run all 54 core PeTTa subsystem tests across protocol, agent, tools, skills, memory, planning, and adaptation:
```bash
.venv/bin/python3 -c "
import subprocess, glob

test_dirs = ['tests/protocol', 'tests/agent', 'tests/tools', 'tests/skills', 'tests/memory', 'tests/planning', 'tests/adaptation']
total, passed, failed = 0, 0, []

for d in test_dirs:
    for f in sorted(glob.glob(f'{d}/*.metta')):
        total += 1
        res = subprocess.run(['/home/hope/.local/bin/petta', f], capture_output=True, text=True)
        if res.returncode == 0 and 'error' not in res.stderr.lower():
            passed += 1
            print(f'PASS: {f}')
        else:
            failed.append((f, res.returncode, res.stderr[:100]))
            print(f'FAIL: {f}')

print(f'\nTotal: {total}, Passed: {passed}, Failed: {len(failed)}')
"
```
*Expected Result:*
```
Total: 54, Passed: 54, Failed: 0
```

### 2.3. Live End-to-End UI Integration Tests
Executes live queries through the real PeTTa engine using the configured LLM provider and verifies unbuffered event streaming, tool execution, and multi-turn conversation context retention:
```bash
.venv/bin/python3 -m unittest -v tests/ui/test_ui_runtime_integration.py
```
*Expected Result:*
```
test_conversation_context_preservation ... ok
test_live_simple_query_with_telemetry_stream ... ok
test_live_tool_execution_with_telemetry ... ok

----------------------------------------------------------------------
Ran 3 tests in 43.675s

OK
```

---

## 3. Test Categories & Verification Scope

| Category | Execution Engine | Mocked vs Live | Verification Scope |
| :--- | :--- | :--- | :--- |
| **Action Protocol** | PeTTa | Deterministic | Parsing canonical S-expressions, rejecting 9th actions and malformed syntax. |
| **Tools & Skills** | PeTTa + Prolog | Deterministic | Built-in arithmetic, string metrics, multi-step workflow execution, execution history. |
| **Persistent Memory** | PeTTa + Prolog | Deterministic | Disk write/read, AtomSpace sync, semantic ranking, contradiction detection, context budgeting. |
| **Goal Planning** | PeTTa | Mocked / Rules | Goal decomposition, DAG task graph construction, acyclicity validation, topological execution. |
| **Adaptation Engine** | PeTTa | Deterministic | Feedback logging, recurring pattern aggregation, dynamic `AdaptationRule` synthesis. |
| **UI Presentation** | Python | Unit | Event dataclasses, task extraction, secret redaction (Gemini/OpenAI keys), styling. |
| **Bridge Transport** | Python | Unit / Mock | Provider selection (`gemini`, `openai`, `deepseek`), error handling, timeouts. |
| **Live Integration** | PeTTa + LLM | Live Provider | End-to-end user query execution, real LLM calls, observation integration, multi-turn memory. |

---

## 4. Test Summary Baseline

- **Total Unit & Regression Tests:** 89 (54 PeTTa + 35 Python)
- **Live Integration Tests:** 3 UI + 6 Subsystem live tests
- **Pass Rate:** 100% across all automated suites.
- **Flaky Tests:** 0 detected.
