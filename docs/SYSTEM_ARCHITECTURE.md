# PeTTa Agentic AI Framework — System Architecture & Engineering Specification

## 1. Executive Summary & Core Philosophy

The **PeTTa Agentic AI Framework** is a neuro-symbolic cognitive architecture that unifies the deductive precision, formal knowledge representation, and deterministic safety of **PeTTa** (Prolog-enhanced MeTTa) with the linguistic fluency and contextual reasoning of **Large Language Models (LLMs)**.

### Core Architectural Principle
**PeTTa owns all agent cognition, orchestration, decision-making, planning, and memory.**  
Python is strictly limited to stateless HTTP transport for LLM/Search APIs and the Streamlit presentation interface.

```text
+-------------------------------------------------------------------------------+
|                       PRESENTATION & CLIENT ENTRYPOINTS                      |
|       Streamlit Web UI (ui/app.py)   |   Terminal CLI (main.metta)            |
|       - 7 Evaluator Demonstrations   |   - Interactive REPL                   |
|       - Unbuffered Live Telemetry    |   - Headless Task Invocation           |
+-------------------------------------------------------------------------------+
                                      |  Safe File IPC (memory/ipc/)
                                      v
+-------------------------------------------------------------------------------+
|                   PeTTa AGENTIC CORE RUNTIME (SWI-Prolog + MeTTa)             |
|                                                                               |
|   1. UI Gateway & Telemetry IO (agent/ui_gateway.metta, telemetry_io.pl)      |
|   2. Cognitive Loop & Single-Step Cycle (agent/loop.metta, prompt.metta)      |
|   3. Canonical 8-Action Protocol Validator (agent/action_validator.metta)     |
|   4. Goal-Driven DAG Planning & Decomposition (agent/goal_planner.metta)      |
|   5. Topological Task Scheduler (agent/task_scheduler.metta)                 |
|   6. DAG Task Execution & Recovery (agent/plan_executor.metta, recovery.metta)|
|   7. Goal Completion Verifier (agent/plan_verifier.metta)                     |
|   8. Execution & Memory Engines:                                              |
|      - Tool Engine (10 tools: read_file, write_file, run_command, web_search...)|
|      - Safety Interceptor (tools/system_primitives.pl - timeout & cmd guard)  |
|      - Skill Workflows (summarize, refine, code_gen)                          |
|      - Memory Lifecycle Manager (Episodic, Semantic, Working)                 |
|      - Adaptive Learning Engine (Reinforcement from feedback signals)         |
+-------------------------------------------------------------------------------+
         |                                           ^
         | AtomSpace Pattern Matching                | py-call (Janus FFI)
         v                                           v
+----------------------------------------+   +----------------------------------+
|      PeTTa SYMBOLIC ATOMSPACES         |   |    PYTHON EXTERNAL TRANSPORT     |
|  &conversation   : Working memory      |   |  python_bridge/bridge.py:        |
|  &long_term      : Persistent facts    |   |    - Google Gemini, OpenAI,      |
|  &goal_space     : Hierarchical goals  |   |      DeepSeek, Generic OpenAI    |
|  &plan_space     : Active task DAGs    |   |  python_bridge/search_bridge.py: |
|  &feedback_space : Reward/penalty logs |   |    - Tavily, Brave, DuckDuckGo   |
|  &adaptation_space: Learned heuristics |   |  (Stateless HTTP APIs only)      |
+----------------------------------------+   +----------------------------------+
```

---

## 2. Canonical Eight-Action Protocol

Every LLM response is strictly parsed into an S-expression and validated by `agent/action_validator.metta` against the canonical grammar before execution:

1. `(answer "<text>")`: Terminal answer or conversational message.
2. `(use_tool <tool_name> (<arg1> ...))`: Deterministic tool execution.
3. `(use_skill <skill_name> (<arg1> ...))`: Multi-step composite skill workflow.
4. `(remember <category> "<key>" "<content>")`: Store fact, preference, goal, or episodic trace into persistent AtomSpace.
5. `(recall <category> "<query>")`: Query persistent memory for relevant knowledge.
6. `(ask_user "<question>")`: Interactive clarification; pauses cycle until user inputs clarification.
7. `(finish)`: Explicitly closes the turn or marks task completion.
8. `(error "<reason>")`: Internal error reporting or graceful recovery trigger.

---

## 3. Tool & Skill Engine with Safety Interception

### Builtin Tools (10 Tools)
- **`read_file ($path)`**: Reads text files safely with size safeguards.
- **`write_file ($path, $content)`**: Safely creates parent folders and writes atomic file contents.
- **`run_command ($command, $approved)`**: Executes shell commands under strict timeout (default 15s). Protected by `is_destructive_command/2` in `tools/system_primitives.pl` which intercepts and rejects destructive commands (`rm -rf`, `mkfs`, `dd`, `shutdown`, fork bombs) unless explicitly pre-approved.
- **`web_search ($query)`**: External web search bridge supporting Tavily, Brave, and DuckDuckGo fallback.
- **`send_message ($msg)`**: Emits user-facing progress updates and notifications.
- **`ask_user ($question)`**: Pauses execution to solicit needed clarifications.
- **`calculator ($expr)`**: Deterministic mathematical arithmetic.
- **`word_counter ($text)`**: Word count analytics.
- **`string_reverser ($text)`**: Deterministic string transformation.
- **`time_now ()`**: ISO-8601 current timestamp generation.

### Composite Skills
- **`summarize_text ($text)`**: Two-pass recursive summarization and key point extraction.
- **`refine_output ($draft, $criteria)`**: Heuristic linting, formatting, and structural refinement.
- **`code_generator ($spec, $lang)`**: Scaffolds code templates conforming to verified contracts.

---

## 4. Multi-Step DAG Planning & Self-Healing

For complex requests, the agent enters the planning pathway (`agent/goal_planner.metta`):
1. **Decomposition**: Evaluates goal and decomposes into an ordered list of atomic subtasks with typed input/output references.
2. **Topological Scheduling (`agent/task_scheduler.metta`)**: Validates dependency cycles and schedules executable tasks in topological order.
3. **Execution & Reference Resolution (`agent/plan_executor.metta`)**: Resolves dynamic inputs (`result_of(task_N)`) from previous outputs.
4. **Plan Recovery & Self-Healing (`agent/plan_recovery.metta`)**: When a task encounters an error, the recovery engine inspects the failure observation, retries with adjusted parameters, or triggers a dynamic replan of dependent tasks.
5. **Goal Verification (`agent/plan_verifier.metta`)**: Validates that all final criteria have been satisfied before synthesizing the final response.

---

## 5. Persistent AtomSpace Memory & Adaptive Learning

- **Hierarchical Memory**: Working memory (`&conversation`), long-term knowledge (`&long_term`), and episodic trace logs are separated to prevent context contamination.
- **Scoring & Consistency**: Memory ranking scores atoms by recency, frequency, and relevance while contradiction detection invalidates stale assertions.
- **Continuous Learning Loop**: Evaluator feedback (ratings, thumbs up/down, corrections) is written to `&feedback_space`. The adaptation engine synthesizes `AdaptationRule` atoms that are injected into future dynamic prompts to continuously improve agent behavior.
