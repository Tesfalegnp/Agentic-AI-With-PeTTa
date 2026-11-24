# PeTTa Agentic AI Framework - Project Notes

**Local Workspace:** `/home/hope/Projects/petta-agentic-ai`  
**GitHub Repository:** [https://github.com/Tesfalegnp/Agentic-AI-With-PeTTa](https://github.com/Tesfalegnp/Agentic-AI-With-PeTTa)  
**Date:** 2026-11-24

---

## 1. What Was Built

A full-stack, production-grade **Agentic AI Framework** where **PeTTa (Prolog-enhanced MeTTa) natively owns all agent intelligence, cognitive reasoning, memory, planning, tools, and skills**, and Python functions strictly as a lightweight LLM/Search transport bridge and Streamlit presentation UI.

### Core Capabilities
- **Canonical Eight-Action Protocol:** Deterministically validated `answer`, `use_tool`, `use_skill`, `remember`, `recall`, `ask_user`, `finish`, `error`.
- **Complete Native Tool Set (10 Tools):** `read_file`, `write_file`, `run_command` (with timeout and destructive approval checks), `send_message`, `ask_user`, `web_search` (Tavily/Brave/DuckDuckGo), `calculator`, `word_counter`, `text_analyzer`, `string_reverser`, `datetime`.
- **Goal-Driven DAG Planning:** Autonomous task decomposition into directed acyclic graphs with topological scheduling, argument reference chaining `(ref t1)`, cycle detection, and recovery.
- **Persistent AtomSpace Memory:** Short-term, episodic, and long-term memory across 5 categories (`preference`, `fact`, `goal`, `project`, `episodic`) with recency/frequency ranking and contradiction detection.
- **Adaptive Self-Improvement:** Explicit feedback recording leading to automated synthesis of `AdaptationRule` atoms.
- **Long-Running Task Execution:** Support for 20+ continuous execution turns with context budgeting and stuck-state detection.
- **Dual Interface:** Interactive continuous CLI (`main.metta` / `agent/controller.metta`) and Streamlit Web UI (`ui/app.py`) featuring 7 Ready-to-Run Evaluator Scenarios.

---

## 2. Key Architectural Decisions

1. **Strict Non-Python Agent Intelligence:** No LangChain, CrewAI, or AutoGen. Reasoning, scheduling, validation, and tool execution occur in PeTTa and SWI-Prolog.
2. **Safe IPC & No Shell Injection:** User requests and parameters are passed via temporary UTF-8 files using Prolog's `read_file_to_string/3` rather than shell string concatenation.
3. **Prolog Unbuffered Telemetry:** Real-time JSONL events are emitted with `flush_output` to `memory/session_events.jsonl`, enabling Streamlit to tail live execution progress without pipe deadlocks.
4. **Destructive Shell Guardrails:** Commands matching dangerous patterns (`rm -rf`, `mkfs`, `dd`, etc.) are blocked unless explicitly passed `Approved=true`.
5. **Configurable Web Search:** Supports Tavily and Brave API keys via `.env` with an automatic zero-config DuckDuckGo HTML fallback when API keys are absent.

---

## 3. How to Run

### Setup Environment
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env # Configure your LLM & Search API keys
```

### Launch Interactive CLI (Continuous Multi-Task Session)
```bash
/home/hope/.local/bin/petta main.metta
```

### Launch Streamlit Web UI
```bash
streamlit run ui/app.py
```

### Run Full Automated Test Suite (108 Tests Passing)
```bash
# Run all 68 PeTTa subsystem tests
python3 -c "
import glob, subprocess
tests = sorted(glob.glob('tests/**/*.metta', recursive=True))
skip = ['test_live_agent.metta', 'test_live_gemini.metta', 'test_memory_live_agent.metta', 'test_memory_aware_live.metta', 'test_adaptation_live.metta', 'test_planning_live.metta']
for t in tests:
    if not any(s in t for s in skip):
        res = subprocess.run(['/home/hope/.local/bin/petta', t], capture_output=True, text=True)
        assert res.returncode == 0, f'Failed: {t}'
print('All 68 PeTTa subsystem tests passed!')
"

# Run all 40 Python unit & bridge tests
.venv/bin/python3 -m unittest discover tests/
```

---

## 4. Evaluator Submission Logs
- Scenario A (Web Research & Calc): [logs/submission/scenario_a_research_calc.log](logs/submission/scenario_a_research_calc.log)
- Scenario B (Multi-Step Dataset Calc): [logs/submission/scenario_b_dataset_calc.log](logs/submission/scenario_b_dataset_calc.log)
- Scenario C (Clarification Flow): [logs/submission/scenario_c_clarification_resumption.log](logs/submission/scenario_c_clarification_resumption.log)
- Simple File Task: [logs/submission/task1_simple_task.log](logs/submission/task1_simple_task.log)
- Multi-Step DAG Task: [logs/submission/task2_multi_step_dag_task.log](logs/submission/task2_multi_step_dag_task.log)
- Long Task (22 Turns): [logs/submission/task3_long_running_task_22_turns.log](logs/submission/task3_long_running_task_22_turns.log)
- Multi-Task Sequential Session: [logs/submission/task4_multi_task_sequential_session.log](logs/submission/task4_multi_task_sequential_session.log)
