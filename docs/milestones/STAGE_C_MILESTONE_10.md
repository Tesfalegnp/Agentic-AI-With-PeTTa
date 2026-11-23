# Stage D — Milestone 10: Memory-Aware Reasoning, Context Management & Agent Intelligence

## 1. Architectural Overview

Milestone 10 extends the PeTTa Agentic AI framework with intelligent, memory-aware reasoning, dynamic relevance ranking, unified context management, strict context budgeting, and conflict detection.

The implementation strictly maintains the core framework boundary:

> **PeTTa owns ALL agent intelligence, reasoning, memory retrieval, relevance ranking, context assembly, budget enforcement, and conflict detection. Python serves strictly as an external LLM API transport bridge via Janus `py-call`.**

```
                       +---------------------------------------+
                       |           User Query / Prompt         |
                       +---------------------------------------+
                                           |
                                           v
                       +---------------------------------------+
                       |          Prompt Engine                |
                       |       (agent/prompt.metta)            |
                       +---------------------------------------+
                          |                |               |
                          v                v               v
               +----------------+  +---------------+  +-------------------+
               | Context Manager|  | Ranking Engine|  | Consistency Check |
               | (context_      |  | (memory_      |  | (memory_          |
               |  manager.metta)|  |  ranking.metta|  |  consistency.     |
               +----------------+  +---------------+  |  metta)           |
                          \                |          +-------------------+
                           \               |               /
                            v              v              v
                       +---------------------------------------+
                       |        Context Budgeting Engine       |
                       |       (agent/context_budget.metta)    |
                       +---------------------------------------+
                                           |
                                           v (Enforced UTF-8 Budget)
                       +---------------------------------------+
                       |       Final Prompt to Provider        |
                       |       (Gemini / OpenAI / DeepSeek)    |
                       +---------------------------------------+
                                           |
                                           v
                       +---------------------------------------+
                       |      Cognitive Agent Reasoning Loop   |
                       |           (agent/loop.metta)          |
                       +---------------------------------------+
```

---

## 2. Dynamic Memory Ranking & Scoring Engine

Memory records stored in the persistent `&long_term` AtomSpace are dynamically ranked and selected for inclusion in the agent's reasoning prompt based on semantic query relevance, priority weighting, and recency.

### 2.1 Relevance Scoring Equation

The ranking score $S$ for a candidate record $R$ given query $Q$, priority $P \in [1, 5]$, and creation timestamp $C_r$ is determined by:

$$S = \begin{cases} 
0, & \text{if } B(R, Q) = 0 \\
B(R, Q) + (P \times 5) + T(C_r), & \text{if } B(R, Q) > 0 
\end{cases}$$

Where:
- **Base Semantic Match Score $B(R, Q)$**:
  - Exact phrase match: $+100$
  - Token / substring intersection: $+15$ per matching token (words $> 3$ characters)
- **Priority Scaling Guard**:
  - **Crucial Rule**: Priority bonus $(P \times 5)$ is applied **ONLY** when $B(R, Q) > 0$. If a record is irrelevant to the query ($B = 0$), its total score is $0$, guaranteeing that high-priority irrelevant records never contaminate the prompt.
- **Recency Boost $T(C_r)$**:
  - A fractional bonus based on the record's age, favoring recent updates for equal semantic matches.
- **Deterministic Tie-Breaking**:
  - Primary: Descending score ($-Score$).
  - Secondary: Descending creation timestamp ($-C_r$).
  - Tertiary: Lexicographical Record ID ($Id_1 < Id_2$).
- **Lifecycle Filter**:
  - Only records with status `active` are evaluated; `superseded` and `archived` records are excluded.

### 2.2 Query-Aware Retrieval API

The primary retrieval API exposed to the agent and prompt engine:

```metta
(memory-retrieve-relevant $query $category $limit)
```

- When `$category` is `all` or `any`, searches across all active records.
- When `$category` is a specific category (e.g., `preference`, `fact`, `project`, `goal`), isolates search to that category.
- Returns a ranked list of `(RankedMemory $score $record)` structures up to `$limit`.

---

## 3. Unified Context Manager & Provenance Attribution

The Context Manager (`agent/context_manager.metta`) creates a structured prompt representation that separates dynamic conversation history from verified persistent memory.

### 3.1 Provenance-Tagged Memory Representation

Each memory injected into the prompt includes explicit provenance metadata:

```
[Memory ID: mem_1 | Category: preference | Priority: 5 | Source: user]
User prefers concise, one-sentence answers.
```

### 3.2 Context Segregation Rules

The system prompt enforces strict cognitive boundaries between:
1. **Conversation Context**: Session working memory, conversational scratchpad, and tool observations.
2. **Persistent Memory Context**: Verified long-term knowledge, retrieved facts, and persistent preferences.
3. **Current User Query**: The immediate instruction to resolve.

The agent prompt instructs the model:
- *Persistent memories represent established truths and preferences across sessions.*
- *If a user query directly conflicts with a stored preference, the agent must ask for clarification (`ask_user`) rather than guessing.*

---

## 4. Prompt Context Budgeting Engine

To ensure robustness across varied LLM context limits and prevent prompt bloat, `agent/context_budget.metta` implements a mathematical context budgeting algorithm.

### 4.1 Budget Allocation Hierarchy

1. **Mandatory Core Prompt (Never Trimmed)**:
   - Agent Identity
   - Canonical 8-Action Protocol
   - Tool Definitions
   - Skill Definitions
   - Few-Shot Grounding Examples
   - Current User Query
2. **Dynamic Context (Trimmed as Needed)**:
   - Critical Consistency Guidance Notices
   - Ranked Persistent Memories
   - Conversation History

### 4.2 Mathematical Trimming Guarantee

$$\text{AvailableBudget} = \text{BudgetLimit} - \text{Length}(\text{CorePrompt} + \text{UserQuery})$$

If $\text{DynamicContent} > \text{AvailableBudget}$, dynamic context is safely truncated to fit within $\text{AvailableBudget}$ without corrupting UTF-8 characters. Persistent memory stored in the AtomSpace is **never mutated** by context trimming.

---

## 5. Memory Consistency & Staleness Manager

The Consistency Manager (`agent/memory_consistency.metta` and `agent/memory_io.pl`) guards the reasoning loop against contradictory knowledge and obsolete information.

### 5.1 Conflict Detection
- **Internal Preference Conflicts**: Scans `&long_term` for opposing preference terms (e.g., `concise` vs `detailed`, `dark mode` vs `light mode`, `formal` vs `casual`).
- **Statement Conflict Detection**: Checks new queries or statements against existing active memories.
- **Guidance Injected into Prompt**:
  When a conflict is detected, the prompt receives a high-priority warning:
  ```
  [CRITICAL MEMORY NOTICE: Contradictory active memory preferences detected: ...
  You MUST ask the user for clarification (action ask_user ...) rather than assuming one over the other.]
  ```

### 5.2 Staleness Check
- Evaluates record age against configurable thresholds using `(check-record-staleness $id $max_age_seconds)`.
- Classifies records as `(RecordFresh $id $age)` or `(RecordStale $id $age)`.

---

## 6. Canonical 8-Action Protocol Alignment

Milestone 10 maintains 100% backward and forward compatibility with the canonical 8-action protocol established in Milestone 6:

1. `(action answer "<content>")`
2. `(action ask_user "<question>")`
3. `(action finish "<summary>")`
4. `(action error "<diagnostic>")`
5. `(action use_tool <tool_name> (<arg1> ...))`
6. `(action use_skill <skill_name> (<arg1> ...))`
7. `(action remember <category> "<content>")`
8. `(action recall <category> "<query>")`

No actions were added, modified, or removed.

---

## 7. Subsystem Modules

| Module | File | Language | Primary Responsibilities |
|---|---|---|---|
| Memory I/O Helpers | `agent/memory_io.pl` | SWI-Prolog | Relevance scoring, record ranking, conflict detection, string truncation, UTF-8 budgeting |
| Store & Space Bindings | `agent/memory_store.metta` | PeTTa | Prolog function imports and AtomSpace bindings |
| Priority Management | `agent/memory_lifecycle.metta` | PeTTa | Dynamic priority rating updates (`memory-set-priority`) |
| Relevance Ranking | `agent/memory_ranking.metta` | PeTTa | `memory-retrieve-relevant`, space ranking, score sorting |
| Consistency Manager | `agent/memory_consistency.metta` | PeTTa | Internal conflict detection, statement conflict check, staleness checking, guidance formatting |
| Context Manager | `agent/context_manager.metta` | PeTTa | Provenance formatting, ranked memory presentation, managed context assembly |
| Context Budget Engine | `agent/context_budget.metta` | PeTTa | Strict context length calculation and deterministic trimming |
| Core Memory Engine | `agent/memory_core.metta` | PeTTa | Store with priority, observation formatting for retrieve actions |
| Agent Prompt Engine | `agent/prompt.metta` | PeTTa | Integration of context manager, budget enforcement, and memory rules |

---

## 8. Verification and Test Suite Matrix

### 8.1 Python Test Suite
- `tests/test_bridge_python.py` & `tests/test_multi_provider_python.py`: **35/35 PASSED** (0.024s).

### 8.2 PeTTa Unit & Integration Regression Suite
- **Stage A & Stage B**:
  - `tests/foundation/test_petta_fundamentals.metta`: **PASS**
  - `tests/protocol/test_action_parsing.metta`: **PASS**
  - `tests/interop/test_py_interop.metta`: **PASS**
  - `tests/interop/test_gemini_bridge.metta`: **PASS**
  - `tests/interop/test_multi_provider_bridge.metta`: **PASS**
- **Stage C Milestone 6 (Cognitive Loop)**:
  - `tests/agent/test_state.metta`: **PASS**
  - `tests/agent/test_parser_validator.metta`: **PASS**
  - `tests/agent/test_prompt.metta`: **PASS**
  - `tests/agent/test_loop_mocked.metta`: **PASS**
- **Stage C Milestone 7 (Tools)**:
  - `tests/tools/test_tool_registry.metta`: **PASS**
  - `tests/tools/test_tool_validator.metta`: **PASS**
  - `tests/tools/test_tool_dispatcher.metta`: **PASS**
  - `tests/tools/test_builtin_tools.metta`: **PASS**
  - `tests/tools/test_tool_history.metta`: **PASS**
  - `tests/integration/test_tool_agent_loop.metta`: **PASS (Live Gemini)**
- **Stage C Milestone 8 (Skills)**:
  - `tests/skills/test_skill_registry.metta`: **PASS**
  - `tests/skills/test_skill_validator.metta`: **PASS**
  - `tests/skills/test_skill_history.metta`: **PASS**
  - `tests/skills/test_skill_workflow.metta`: **PASS**
  - `tests/skills/test_builtin_skills.metta`: **PASS**
  - `tests/skills/test_skill_executor.metta`: **PASS**
  - `tests/skills/test_skill_agent_loop_mocked.metta`: **PASS**
  - `tests/integration/test_skill_agent_loop.metta`: **PASS (Live Gemini)**
- **Stage C Milestone 9 (Persistent Memory)**:
  - `tests/memory/test_atomspace.metta`: **PASS**
  - `tests/memory/test_memory_validator.metta`: **PASS**
  - `tests/memory/test_memory_crud_retrieval.metta`: **PASS**
  - `tests/memory/test_memory_lifecycle.metta`: **PASS**
  - `tests/memory/test_memory_consolidation.metta`: **PASS**
  - `tests/memory/test_malformed_record_resilience.metta`: **PASS**
  - `tests/memory/test_memory_agent_loop_mocked.metta`: **PASS**
  - `tests/integration/test_memory_live_agent.metta`: **PASS (Live Gemini)**

### 8.3 Milestone 10 Specific Test Suites
1. **`tests/memory/test_memory_ranking.metta`**: **PASS** (Exact match dominance, category isolation, priority boosting on relevant items, exclusion of irrelevant items regardless of priority, exclusion of superseded/archived records, limit enforcement).
2. **`tests/memory/test_memory_context_manager.metta`**: **PASS** (Empty context handling, conversation history capture, selective relevance with full provenance, dynamic conflict guidance integration).
3. **`tests/memory/test_memory_context_budget.metta`**: **PASS** (Intact prompt within budget, tight budget trimming preserving instructions and user query within 350 char limit, persistent memory AtomSpace remaining unmutated).
4. **`tests/memory/test_memory_consistency.metta`**: **PASS** (Clean memory pass, contradictory active preference detection, statement conflict detection, record staleness threshold verification, consistency guidance formatting).
5. **`tests/memory/test_memory_aware_loop.metta`**: **PASS** (Memory-aware prompt assembly, irrelevant memory exclusion, contradictory preference notice integration, canonical action parsing across scenarios, iteration limit guard).
6. **`tests/integration/test_memory_aware_live.metta`**: **PASS (Live Gemini 3.5)**:
   - **Scenario A (Preference Recall)**: Correctly applied concise style.
   - **Scenario B (Project Context)**: Retrieved Project Chimera knowledge accurately.
   - **Scenario C (Irrelevant Filtering)**: Handled unrelated query without memory contamination.
   - **Scenario D (Conflicting Preferences)**: Handled contradictory preferences with awareness and appropriate explanation.
   - **Scenario E (Empty Memory)**: Truthfully reported lack of records without hallucination.
