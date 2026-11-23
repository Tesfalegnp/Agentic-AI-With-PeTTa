# Stage D — Milestone 11: Goal-Driven Planning, Task Decomposition & Execution Control

## 1. Architectural Overview

Milestone 11 extends the PeTTa Agentic AI framework with autonomous goal-driven planning, task decomposition, dependency graph validation, topological scheduling, step-by-step execution, dynamic argument reference resolution, failure recovery, and completion verification.

The implementation strictly maintains the core framework boundary:

> **PeTTa owns ALL agent intelligence, reasoning, planning, task decomposition, graph validation, dependency scheduling, tool/skill selection, step execution, observation handling, progress tracking, failure recovery decisions, completion verification, and planning history. Python serves strictly as an external LLM API transport bridge via Janus `py-call`.**

Furthermore, the **canonical 8-action protocol** is strictly preserved:
- `(action answer "<text>")`
- `(action ask_user "<question>")`
- `(action finish "<summary>")`
- `(action error "<type>" "<message>")`
- `(action use_tool <name> (<args>))`
- `(action use_skill <name> (<args>))`
- `(action remember <category> <content> <priority>)`
- `(action recall <category> <query> <limit>)`

**NO 9th action was introduced.** When a multi-step workflow is requested, the cognitive loop invokes the PeTTa planning subsystem, which solicits a structured `(plan-proposal ...)` S-expression from the LLM, validates and converts it into a verifiable dependency graph in PeTTa's `&plan_space`, executes the plan step by step using the canonical tool and skill engines, and returns a verified final answer or summary to the user.

```
                       +---------------------------------------+
                       |           User Query / Goal           |
                       +---------------------------------------+
                                           |
                                           v
                       +---------------------------------------+
                       |       Deterministic Planning Check    |
                       |          (agent/plan_io.pl)           |
                       +---------------------------------------+
                                     /           \
               Single-Step / Simple /             \ Multi-Step Workflow
                                   v               v
                +--------------------+    +-----------------------------+
                | Standard Cognitive |    | Goal & Prompt Construction  |
                |       Loop         |    | (agent/goal_planner.metta)  |
                +--------------------+    +-----------------------------+
                                                         |
                                                         v
                                          +-----------------------------+
                                          | LLM Plan Proposal Generation|
                                          |   (via Janus py-call)       |
                                          +-----------------------------+
                                                         |
                                                         v
                                          +-----------------------------+
                                          | Plan Proposal Builder       |
                                          | (agent/plan_builder.metta)  |
                                          +-----------------------------+
                                                         |
                                                         v
                                          +-----------------------------+
                                          | Graph Validator & DAG Sort  |
                                          | (agent/plan_validator.metta)|
                                          +-----------------------------+
                                                         |
                                                         v
                                          +-----------------------------+
                                          | Task Scheduler (Ready Queue)|
                                          | (agent/task_scheduler.metta)|
                                          +-----------------------------+
                                                         |
                                                         v
                                          +-----------------------------+
                                          | Step Execution & Ref Engine |
                                          | (agent/plan_executor.metta) |
                                          +-----------------------------+
                                                   /            \
                                                  /              \
                                          [Tool Dispatch]   [Skill Dispatch]
                                                  \              /
                                                   \            /
                                          +-----------------------------+
                                          | Failure Recovery & Retry    |
                                          | (agent/plan_recovery.metta) |
                                          +-----------------------------+
                                                         |
                                                         v
                                          +-----------------------------+
                                          | Goal Completion Verifier    |
                                          | (agent/plan_verifier.metta) |
                                          +-----------------------------+
                                                         |
                                                         v
                                          +-----------------------------+
                                          | Plan History & Final Output |
                                          | (agent/plan_history.metta)  |
                                          +-----------------------------+
```

---

## 2. Planning Subsystem Modules

The planning architecture consists of 11 PeTTa/Prolog modules in `agent/`:

| Module | Responsibilities | Key Functions / Spaces |
|---|---|---|
| `agent/plan_io.pl` | SWI-Prolog helper for DAG graph validation using `library(ugraphs)`, cycle detection, topological sorting, planning requirement heuristics, timestamping, and string cleaning. | `validate_plan_graph/3`, `compute_topological_sort/2`, `is_planning_required/2`, `clean_plan_string/2` |
| `agent/plan_types.metta` | Type definitions and status predicate validators for goals, plans, tasks, and executors. | `is-valid-goal-status`, `is-valid-plan-status`, `is-valid-task-status`, `is-valid-executor-type` |
| `agent/goal_manager.metta` | Goal lifecycle management in `&goal_space`. Supports creating, updating, querying, and listing goals. | `goal-create`, `goal-get`, `goal-update-status`, `goal-list-active`, `goal-list-all`, `goal-clear` |
| `agent/plan_state.metta` | Central plan and task state storage in `&plan_space`. Handles task insertion, status transitions, result storage, and foreign imports. | `plan-create`, `plan-add-task`, `plan-get`, `plan-get-tasks`, `task-get`, `task-update-status`, `plan-update-status`, `plan-clear-all` |
| `agent/plan_history.metta` | Audit logging space `&plan_history` recording chronological plan creation, completion, failure, and execution metrics. | `plan-history-record`, `plan-history-list`, `plan-history-clear` |
| `agent/plan_builder.metta` | Parses raw LLM output into structured PeTTa atoms, strips code fences, parses S-expressions using `safe-sread`, normalizes task arguments, and populates `&plan_space`. | `build-plan-from-proposal`, `clean_plan_string`, `normalize-task-args`, `populate-plan-tasks` |
| `agent/plan_validator.metta` | Structural and semantic validation of plans. Verifies tool/skill existence and active status, argument formats, dynamic `(ref ...)` references, and DAG acyclicity via `plan_io.pl`. | `validate-plan`, `validate-task-list`, `validate-single-task`, `validate-task-refs`, `tasks-to-prolog-tuples` |
| `agent/task_scheduler.metta` | Dependency-aware scheduling engine. Evaluates task dependencies, computes ready tasks, selects next executable task, and tracks pending/blocked states. | `schedule-next-task`, `update-pending-tasks`, `check-deps-status`, `count-tasks-with-status`, `get-ready-tasks` |
| `agent/plan_executor.metta` | Step execution engine. Resolves dynamic `(ref <task_id>)` argument dependencies against prior task outputs, dispatches tools and skills, handles errors, and loops until completion. | `execute-plan`, `execute-plan-loop`, `execute-task-step`, `resolve-task-args`, `resolve-single-arg` |
| `agent/plan_recovery.metta` | Failure recovery and replanning engine. Manages per-task retry budgets (max 2 retries) and per-goal replan limits (max 1 replan), with truthful failure propagation. | `can-retry-task`, `record-task-retry`, `can-replan-goal`, `record-goal-replan`, `recovery-reset` |
| `agent/plan_verifier.metta` | Goal completion verification engine. Verifies all tasks completed successfully, validates non-empty outputs, and assesses goal fulfillment. | `verify-plan-completion`, `verify-task-results` |
| `agent/goal_planner.metta` | High-level planning coordinator. Determines whether planning is required, builds planning prompts with context and tool/skill schemas, orchestrates proposal parsing, validation, execution, and verification. | `should-plan-request`, `build-planning-prompt`, `plan-and-execute-request`, `plan-build-and-run`, `plan-validate-and-run`, `plan-execute-and-verify` |

---

## 3. Goal Lifecycle & State Transitions

Goals and plans follow well-defined, validated state transitions:

### 3.1 Goal States
- `active`: Goal registered and awaiting plan creation.
- `in-progress`: Plan validated and actively executing.
- `completed`: All tasks verified and goal objective fulfilled.
- `failed`: Non-recoverable task failure or replan budget exhausted.
- `suspended`: Execution paused for user clarification (`ask_user`).
- `replanning`: Re-evaluating proposal after a recoverable step failure.

### 3.2 Task States
- `pending`: Waiting for upstream dependency tasks to complete.
- `ready`: All upstream dependencies completed; eligible for scheduling.
- `running`: Currently being executed by the tool or skill dispatcher.
- `completed`: Successfully executed with validated output.
- `failed`: Execution failed (returned tool/skill error).
- `skipped`: Bypassed due to upstream failure or conditional branching.
- `blocked`: Unexecutable because an upstream dependency failed.

---

## 4. Plan Proposal Grammar & Builder

When the agent determines that a user request requires multi-step planning, it generates a prompt instructing the LLM to output a strictly formatted S-expression conforming to the following grammar:

```lisp
(plan-proposal "<description>"
  ((task <task_id> <executor_type> <name> (<args>) (<deps>))
   ...))
```

Where:
- `<description>`: A string explaining the objective of the plan.
- `<task_id>`: Unique atom identifying the task (e.g., `t1`, `t2`, `t3`).
- `<executor_type>`: Either `tool` or `skill`.
- `<name>`: The registered tool or skill name (e.g., `word_counter`, `calculator`, `research_topic`).
- `<args>`: List of arguments. Arguments can be literals (e.g., `"sample text"`, `42`) or dynamic references to outputs of preceding tasks: `(ref <task_id>)`.
- `<deps>`: List of dependency task IDs that must complete before this task can execute (e.g., `(t1)` or `()`).

The proposal parser (`agent/plan_builder.metta`) uses `safe-sread` and `clean_plan_string` to strip Markdown formatting (e.g. ` ```lisp ... ``` `) and instantiate records in `&plan_space`.

---

## 5. Graph Validation & DAG Acyclicity

Before any plan is executed, `agent/plan_validator.metta` performs comprehensive structural and semantic verification:

1. **Existence Verification**: Verifies that every task references a tool or skill registered in `&tool_registry` or `&skill_registry`.
2. **Enabled Verification**: Ensures that referenced tools/skills have status `enabled`.
3. **Reference Integrity**: Verifies that any dynamic reference `(ref <id>)` refers to a task `<id>` defined within the same plan proposal.
4. **Dependency Integrity**: Verifies that all dependencies in `<deps>` correspond to valid task IDs in the plan.
5. **No Self-Dependencies**: Rejects tasks that declare a dependency on themselves (`t1 -> t1`).
6. **DAG Acyclicity & Topological Sorting**: Delegates task pairs `(TaskId, DepsList)` to SWI-Prolog `agent/plan_io.pl`, which constructs a directed graph using SWI-Prolog's standard `library(ugraphs)`:
   - Validates that the graph contains no cycles (`top_sort` succeeds).
   - If a cycle exists (e.g., `t1 -> t2 -> t1`), the plan is rejected with `(PlanValidationFailed (CycleDetected ...))`.
   - Produces a valid topological sort order verifying that dependencies can be scheduled.

---

## 6. Dependency-Aware Scheduling & Dynamic Reference Execution

### 6.1 Scheduling
`agent/task_scheduler.metta` dynamically assesses the status of all tasks in `&plan_space`:
- Inspects pending tasks. If all tasks listed in a task's `<deps>` have status `completed`, the task transitions to `ready`.
- If any upstream dependency has status `failed` or `blocked`, the pending task transitions to `blocked`.
- `schedule-next-task` returns the next `ready` task in topological sequence.

### 6.2 Step Execution & Reference Resolution
`agent/plan_executor.metta` manages step execution:
- Resolves dynamic references `(ref <id>)` in the task's arguments by querying the output of task `<id>` stored in `&plan_space`.
- For `tool` tasks: dispatches execution to `dispatch-tool`.
- For `skill` tasks: dispatches execution to `execute-skill`.
- Records tool/skill execution output in `&plan_space` for consumption by downstream tasks.
- Updates task status to `completed` or `failed`.
- Logs execution events in `&plan_history`.

---

## 7. Failure Recovery & Replanning

When a step execution fails (e.g., division by zero or invalid input):
1. **Per-Task Retry**: `agent/plan_recovery.metta` checks whether retry budget is available (`can-retry-task`, default max 2 retries). If eligible, the task status is set to `ready` for re-execution.
2. **Dependent Task Blocking**: Downstream tasks that depend on the failed task are transitioned to `blocked` to prevent invalid cascades.
3. **Per-Goal Replanning**: If retries fail or a structural error occurs, `can-replan-goal` checks if replan budget is available (default max 1 replan per goal).
4. **Truthful Propagation**: If replanning is exhausted, the plan and goal transition to `failed`, and the agent returns a truthful non-completion explanation without hallucinations.

---

## 8. Goal Completion Verification

`agent/plan_verifier.metta` evaluates the completed plan:
- Verifies that all tasks in the plan reached `completed` status.
- Validates that each completed task produced a non-empty, valid observation.
- Returns `(PlanVerifiedSuccess <PlanId>)` or `(PlanVerificationFailed <Reason>)`.
- `goal_planner.metta` compiles the final outputs of terminal tasks into a synthesized response or summary for the user.

---

## 9. Verification & Test Suite Summary

### 9.1 Unit Test Suites (`tests/planning/`)
All 9 unit test suites execute natively in PeTTa and pass 100%:

| Test Suite | Purpose | Assertions / Cases | Result |
|---|---|---|---|
| `test_goal_manager.metta` | Goal creation, retrieval, status transitions, active filtering, cleanup | 5 test cases | **PASS ✅** |
| `test_plan_builder.metta` | S-expression parsing, code-fence stripping, argument normalization, malformed proposal rejection | 4 test cases | **PASS ✅** |
| `test_plan_validator.metta` | Valid plan acceptance, unknown tool rejection, disabled tool rejection, missing dependency detection, cycle detection, self-dependency rejection | 7 test cases | **PASS ✅** |
| `test_task_scheduler.metta` | Initial ready task selection, state progression, all-completed detection, blocked task handling | 5 test cases | **PASS ✅** |
| `test_plan_executor.metta` | Tool execution, skill execution, dynamic argument reference pipeline (`t1 -> t2`) | 3 test cases | **PASS ✅** |
| `test_plan_recovery.metta` | Retry budget enforcement, retry limit exhaustion, replan budget enforcement, unrecoverable error reporting | 4 test cases | **PASS ✅** |
| `test_plan_verifier.metta` | Complete plan verification, incomplete plan detection, failed task detection | 3 test cases | **PASS ✅** |
| `test_plan_history.metta` | History event recording, chronological ordering, history clearing | 3 test cases | **PASS ✅** |
| `test_planning_agent_loop.metta` | Deterministic planning decision, memory-aware planning prompt assembly, end-to-end plan execution | 3 test cases | **PASS ✅** |

### 9.2 Live Integration Test Suite (`tests/integration/test_planning_live.metta`)
Executed against live Gemini LLM (`gemini-2.5-flash`):

- **Scenario A (Direct Answer)**: Factual query. Planning heuristic correctly determines that no plan is needed; agent answers directly via `answer` without creating goals or plans. **PASS ✅**
- **Scenario B (Single Tool Execution)**: Simple arithmetic calculation. Planning heuristic correctly skips planning; agent executes tool directly via `use_tool calculator`. **PASS ✅**
- **Scenario C (Multi-Step Tool Workflow)**: Complex text analysis workflow requiring word count and text analysis report. Planning heuristic triggers planning; LLM generates `(plan-proposal ...)`; plan parsed, validated as DAG, scheduled, executed with dynamic reference `(ref t1)`, verified, and summarized. **PASS ✅**
- **Scenario D (Skill-Based Workflow)**: Multi-step task combining skills. Skill workflow executed, validated, scheduled, and verified. **PASS ✅**
- **Scenario E (Failure Recovery & Truthful Reporting)**: Tool error injected (division by zero). Dependent task blocked; recovery budget checked; truthful explanation of failure returned without hallucination. **PASS ✅**
- **Scenario F (Memory-Aware Planning)**: User preferences retrieved from persistent memory and incorporated into planning context; plan tasks adhere to preferences. **PASS ✅**
- **Scenario G (Ambiguous Goal)**: Ambiguous goal provided; agent requests clarification using `ask_user` action. **PASS ✅**

### 9.3 Regression Test Suite (Milestones 1–11)
- Python Unit Tests (`tests/test_bridge_python.py`, `tests/test_multi_provider_python.py`): **35/35 PASSED** (0.021s).
- Full PeTTa Unit & Integration Regression Suite (Milestones 1 through 11): **100% PASSED**.
