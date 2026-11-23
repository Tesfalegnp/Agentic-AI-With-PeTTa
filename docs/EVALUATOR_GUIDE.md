# PeTTa Agentic AI Framework: Academic Evaluator Demonstration Guide

**Project:** `petta-agentic-ai`  
**Workspace:** `/home/hope/Projects/petta-agentic-ai`  
**Target Repository:** `https://github.com/Tesfalegnp/Agentic-AI-With-PeTTa`  
**Audience:** Academic Evaluators, Software Architecture Reviewers, and Project Assessors  

---

## 1. Evaluator Quick Orientation

This guide provides a structured walkthrough for evaluating the **PeTTa Agentic AI Framework**. 

### What Makes This Project Unique?
Most modern agentic AI systems are implemented entirely in Python or JavaScript, using frameworks like LangChain, CrewAI, or AutoGen where all control flow, prompt manipulation, and tool logic reside in procedural code. 

In contrast, this project establishes **PeTTa (Prolog-enhanced MeTTa)** as the **primary agent intelligence runtime**:
- **Symbolic Reasoning & State:** The agent's cognitive loop, memory retrieval, task planning, and rule synthesis are executed within PeTTa AtomSpaces.
- **Deterministic Action Validation:** The agent enforces a strict canonical **8-action protocol** (`answer`, `use_tool`, `use_skill`, `remember`, `recall`, `ask_user`, `finish`, `error`) via formal S-expressions.
- **Role of Python:** Python is strictly confined to external HTTP transport (communicating with LLM APIs) and web UI presentation (Streamlit). No agent reasoning or decision-making occurs in Python.

---

## 2. Launching the Evaluation Environment

Open a terminal on the host machine:

```bash
cd /home/hope/Projects/petta-agentic-ai

# 1. Activate Python virtual environment
source .venv/bin/activate

# 2. Launch the interactive Web User Interface
streamlit run ui/app.py
```

The browser will open automatically at **`http://localhost:8501`**.

---

## 3. UI Overview & Transparency Features

```
+------------------------------------------------------------------------------------+
| SIDEBAR: Subsystem Transparency           | MAIN WORKSPACE: Chat & Execution Feed |
|-------------------------------------------|----------------------------------------|
| - LLM Provider: gemini (gemini-2.5-flash) | - Header Banner: Architecture Badges   |
| - Subsystem Status:                       | - Quick Evaluator Demo Prompt Buttons  |
|   * Memory Records: N                     | - Chat History (User & Assistant)      |
|   * Active Adaptations: M                 | - Live Real-Time Execution Stream      |
| - Tools Registry (5 built-in tools)       |   (st.status showing genuine events)   |
| - Skills Registry (3 composite skills)    | - Visual Task Cards (Plan DAG status)  |
| - Active Learned Preferences list         | - Assistant Response & Metrics         |
| - Session Controls: Clear Conversation    | - Feedback Buttons (👍 / 👎)           |
| - 🏛️ Architecture Details Expander        | - Bottom Chat Input                    |
+------------------------------------------------------------------------------------+
```

---

## 4. Five Structured Demonstration Scenarios

The web interface includes one-click buttons for five key evaluation scenarios:

### Scenario 1: Direct Factual Reasoning with Working Memory Context
- **One-Click Button:** 🌍 **Capital of France**
- **Query:** `"What is the capital of France?"`
- **What to Observe in the UI:**
  1. The live execution status expands showing:
     - `init`: User request received by PeTTa runtime.
     - `reasoning`: Evaluating reasoning path (single-step path chosen).
     - `context`: Dynamic prompt assembled with working memory and action protocol.
     - `llm`: Querying LLM provider via Python bridge.
     - `action`: Canonical action parsed: `(action answer "The capital of France is Paris.")`.
     - `complete`: Final answer delivered to user.
  2. The assistant responds: `"The capital of France is Paris."`
- **PeTTa Code Mapping:**
  - Cognitive Cycle: `agent/loop.metta` (`run-cognitive-cycle`, lines 122–153)
  - Action Validation: `agent/action_validator.metta`
- **Automated Test:** `tests/protocol/test_action_parsing.metta`

---

### Scenario 2: Single-Tool Dispatch and Computation
- **One-Click Button:** 🔢 **Calculate 45 * 12**
- **Query:** `"Calculate 45 multiplied by 12."`
- **What to Observe in the UI:**
  1. Multi-turn reasoning cycle:
     - **Iteration 1:** The LLM issues `(action use_tool calculator ("45 * 12"))`.
     - **Tool Dispatch:** PeTTa validates the tool name and dispatches execution to Prolog's `is/2` engine.
     - **Observation:** `[Observation from calculator]: 540` is captured and appended to `&conversation`.
     - **Iteration 2:** The LLM receives the observation and produces `(action answer "45 multiplied by 12 is 540.")`.
  2. Final response: `"45 multiplied by 12 is 540."`
- **PeTTa Code Mapping:**
  - Tool Registry: `agent/tool_registry.metta`
  - Tool Dispatcher: `agent/tool_dispatcher.metta`
  - Arithmetic Engine: `tools/calculator_io.pl`
- **Automated Test:** `tests/tools/test_tool_dispatcher.metta`

---

### Scenario 3: Composite Multi-Step Skill Execution
- **One-Click Button:** 📊 **Text Metrics Analysis**
- **Query:** `"Analyze this text: 'PeTTa enables native symbolic reasoning combined with neural language models.'"`
- **What to Observe in the UI:**
  1. The LLM selects a composite skill: `(action use_skill text_analysis_skill ("..."))`.
  2. PeTTa's skill executor coordinates multiple sub-steps:
     - Word counting via `word_counter`
     - Character profiling via `char_counter`
     - Structural metric aggregation
  3. Structured observation is returned: `Word count: 10 | Char count: 72 | Category: medium | Status: ok`.
  4. Final response delivers the analyzed breakdown.
- **PeTTa Code Mapping:**
  - Skill Registry: `agent/skill_registry.metta`
  - Skill Executor: `agent/skill_executor.metta`
- **Automated Test:** `tests/skills/test_builtin_skills.metta`

---

### Scenario 4: Goal Decomposition, DAG Scheduling & Dependency Execution
- **One-Click Button:** 📋 **Multi-step Text Workflow**
- **Query:** `"Create a multi-step workflow to analyze the words in 'Symbolic AI and LLM integration' and calculate the square of that word count."`
- **What to Observe in the UI:**
  1. `is_planning_required` detects multi-step dependencies and engages `agent/goal_planner.metta`.
  2. The LLM planner proposes a structured plan DAG:
     - **Task 1:** `word_counter ("Symbolic AI and LLM integration")` (deps: none)
     - **Task 2:** `calculator ("<T1_OUTPUT> * <T1_OUTPUT>")` (deps: Task 1)
     - **Task 3:** `echo ("Analysis complete: ...")` (deps: Task 2)
  3. **Visual Task Cards** appear in the live feed showing real-time state transitions:
     - ⏳ `PENDING` -> ⚡ `RUNNING` -> ✅ `COMPLETED`
  4. All dependency bindings resolve correctly and `(action finish ...)` concludes execution.
- **PeTTa Code Mapping:**
  - DAG Planning: `agent/goal_planner.metta`
  - DAG Validator & Acyclicity: `agent/plan_validator.metta`
  - Task Scheduler: `agent/task_scheduler.metta`
  - Plan Executor: `agent/plan_executor.metta`
- **Automated Test:** `tests/planning/test_planning_agent_loop.metta`

---

### Scenario 5: User Feedback & Dynamic Adaptation Evolution
- **Demonstration Steps:**
  1. Ask any question in chat (e.g., `"Explain recursion in programming."`).
  2. When the assistant responds, click the 👎 **Not Helpful** button under the message.
  3. In the feedback dialog, select category `conciseness` and submit.
  4. PeTTa records the explicit feedback event into `&feedback_space`.
  5. Upon recurring patterns, PeTTa synthesizes an `AdaptationRule` stored in `&adaptation_space`.
  6. Look at the sidebar: **Active Adaptations** increments.
  7. Ask a subsequent question: PeTTa automatically injects the learned preference into the prompt without code changes!
- **PeTTa Code Mapping:**
  - Feedback Gateway: `agent/feedback_gateway.metta`
  - Feedback Store: `agent/feedback_store.metta`
  - Adaptation Engine: `agent/adaptation_engine.metta`
- **Automated Test:** `tests/adaptation/test_adaptation_prompt_integration.metta`

---

## 5. Evaluator Inspection Checklist

| Capability | What to Check | File to Inspect |
| :--- | :--- | :--- |
| **Purity of PeTTa Reasoning** | Confirm no agent logic or prompt loops are in Python. | `python_bridge/bridge.py`<br>`agent/loop.metta` |
| **Canonical 8-Action Protocol** | Confirm exact 8 actions with no 9th action or JSON Schema. | `agent/action_validator.metta`<br>`docs/AGENT_PROTOCOL.md` |
| **AtomSpace Memory** | Confirm memory records are stored as MeTTa atoms. | `agent/memory_core.metta`<br>`memory/long_term/` |
| **Acyclicity in Planning** | Confirm plans are DAGs with cycle detection. | `agent/plan_validator.metta`<br>`agent/plan_io.pl` |
| **Live Telemetry Emission** | Confirm events are emitted natively from Prolog with `flush_output`. | `agent/telemetry_io.pl`<br>`agent/telemetry.metta` |
| **Secret Masking Safety** | Confirm API keys are redacted before UI display. | `ui/event_protocol.py`<br>`tests/ui/test_ui_safety.py` |
