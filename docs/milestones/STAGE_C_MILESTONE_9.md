# Stage C — Milestone 9: Long-Term Disk-Backed Persistent Memory

## 1. Architectural Overview

Milestone 9 implements the persistent cognitive memory architecture for `petta-agentic-ai`. The system strictly adheres to the core framework tenet:

> **PeTTa owns ALL agent intelligence, memory models, storage, retrieval, lifecycle, and consolidation. Python is exclusively an external LLM API transport layer via Janus/`py-call`.**

Persistent memory allows the PeTTa reasoning agent to retain facts, user preferences, long-term goals, project context, and episodic histories across sessions and independent process restarts.

```
                      +---------------------------------------+
                      |       PeTTa Agent Cognitive Loop      |
                      |           (agent/loop.metta)          |
                      +---------------------------------------+
                                  |               ^
           (action remember ...)  |               |  (action recall ...)
                                  v               |
                      +---------------------------------------+
                      |          agent/memory_core.metta      |
                      +---------------------------------------+
                                  |
         +------------------------+-------------------------+
         |                        |                         |
         v                        v                         v
+------------------+    +-------------------+    +--------------------+
|   Short-Term     |    |     Long-Term     |    |      Episodic      |
|    Working       |    |     Semantic      |    |       Event        |
|    AtomSpace     |    |     AtomSpace     |    |     AtomSpace      |
|   (&short_term)  |    |    (&long_term)   |    |    (&episodic)     |
+------------------+    +-------------------+    +--------------------+
         |                        |                         |
         | (Consolidation)        | (Safe Serialization)    |
         +----------------------->|                         |
                                  v                         v
                       +--------------------+    +--------------------+
                       |  long_term_store   |    |   episodic_store   |
                       |       (.data)      |    |       (.data)      |
                       +--------------------+    +--------------------+
```

---

## 2. Multi-AtomSpace Memory Model

Milestone 9 isolates memory categories across four independent PeTTa AtomSpaces:

| AtomSpace | Name | Purpose | Retention |
|---|---|---|---|
| `&short_term` | Working Session Memory | Holds temporary findings, active plan scratchpads, intermediate step facts | Session only; clears on consolidation or reset |
| `&long_term` | Semantic Persistent Store | Stores validated facts, user preferences, persistent goals, project knowledge | Permanent; serialized to disk |
| `&episodic` | Episodic Event Store | Chronological log of high-level interaction events, milestones, and agent actions | Permanent; serialized to disk |
| `&memory_history`| Audit History Space | Immutable log of all memory operations (`remember`, `recall`, `consolidate`, `delete`) | In-memory session audit trail |

---

## 3. Memory Record Schema

Every record in `&long_term` and `&episodic` conforms to the canonical `MemoryRecord` functor:

```metta
(MemoryRecord $id $category $type $content $created_at $updated_at $source $priority $tags $status)
```

- **`$id`**: Unique identifier string (`"mem_1"`, `"mem_2"` for long-term; `"evt_1"`, `"evt_2"` for episodic).
- **`$category`**: Bounded category symbol: `fact`, `preference`, `goal`, `project`, `episodic`.
- **`$type`**: Memory classification: `semantic`, `procedural`, `episodic`, or `working`.
- **`$content`**: Plain text string containing the recorded knowledge.
- **`$created_at`**: Integer UNIX timestamp.
- **`$updated_at`**: Integer UNIX timestamp of last modification or supersede.
- **`$source`**: Originator symbol (`user`, `agent`, or `system`).
- **`$priority`**: Numeric importance rating (1 to 5).
- **`$tags`**: List of categorization tag symbols.
- **`$status`**: Lifecycle state symbol: `active`, `superseded`, or `archived`.

---

## 4. Safe Disk Serialization & Security Boundary

### 4.1 Storage Format
Memory files reside in dedicated directories:
- `memory/long_term/long_term_store.data`
- `memory/episodic/episodic_store.data`

Records are serialized line-by-line using safe Prolog terms:
```prolog
mem_rec("mem_1", fact, semantic, "User favorite programming language is Prolog.", 1763784180, 1763784180, user, 1, [], active).
```

### 4.2 Security Protections
1. **No Code Execution**: Storage files are parsed line-by-line via `read_line_to_string` and `read_term_from_atom(Line, Term, [syntax_errors(quiet)])`. Terms are checked strictly against `mem_rec/10` unification. Metta/Prolog code injection lines (e.g. `!(system("rm -rf /")).`) fail unification and are discarded with zero execution.
2. **Syntax Error Resilience**: Malformed or truncated lines do not crash the parser; `syntax_errors(quiet)` catches them silently and advances the stream to the next line.
3. **Sensitive Information Filter**: `agent/memory_validator.metta` inspects incoming content and rejects sensitive credentials (`api_key`, `sk-`, `aiza`, `password`, `secret`, `bearer `, `token=`) before any atom can be created or written to disk.

---

## 5. Memory Subsystem Modules

| Module | Location | Responsibilities |
|---|---|---|
| `memory_io.pl` | `agent/memory_io.pl` | Prolog primitive helpers: `save_records_from_space/3`, `load_records_into_space/3`, `sub_string_match/3`, `is_sensitive_text/2`, `get_timestamp/1`, `clear_storage_file/2`. |
| `memory_types.metta` | `agent/memory_types.metta` | Type definitions, valid category checkers, default memory types. |
| `memory_validator.metta` | `agent/memory_validator.metta` | Validation of categories, non-empty content, and rejection of credentials. |
| `memory_store.metta` | `agent/memory_store.metta` | AtomSpaces (`&short_term`, `&long_term`, `&episodic`, `&memory_history`), ID generation, duplicate checking, audit logging. |
| `memory_retrieval.metta` | `agent/memory_retrieval.metta` | Query matching, substring case-insensitive search, category filtering. |
| `memory_lifecycle.metta` | `agent/memory_lifecycle.metta` | Memory record updating, superseding, soft deleting, short-term clearing, complete reset. |
| `memory_consolidation.metta` | `agent/memory_consolidation.metta` | Short-term to long-term promotion and episodic event recording. |
| `memory_persistence.metta` | `agent/memory_persistence.metta` | Disk save and load operations. |
| `memory_core.metta` | `agent/memory_core.metta` | Unified public API (`memory-store`, `memory-recall-query`, `format-memory-observation`, `memory-init`, `memory-shutdown`). |
| `memory_prompt.metta` | `agent/memory_prompt.metta` | Formatter for injecting top recalled persistent memories directly into system prompts. |

---

## 6. Action Protocol Integration

The canonical PeTTa Action Protocol was updated to activate the two persistent memory actions:

1. **`remember` Action**:
   ```metta
   (action remember <category> "<content>")
   ```
   Validated by `agent/action_validator.metta`, dispatched in `agent/loop.metta` via `memory-store`, auto-persisted to disk, and formatted into observation:
   ```
   [Observation from memory remember]: Successfully remembered fact with ID mem_1.
   ```

2. **`recall` Action**:
   ```metta
   (action recall <category> "<query>")
   ```
   Dispatched via `memory-recall-query`, returns matching content, and formats into observation:
   ```
   [Observation from memory recall (fact)]: ("User favorite programming language is Prolog.")
   ```

3. **Lifecycle Hooks**:
   `agent/controller.metta` executes `(memory-init)` on boot to load records from disk into AtomSpaces, and executes `(memory-shutdown)` upon agent shutdown to persist all memory records to disk.

---

## 7. Verification Results

All 9 Milestone 9 test suites pass with 100% assertion success:
- `test_memory_validator.metta`: Valid categories accepted; empty strings and credentials rejected.
- `test_memory_crud_retrieval.metta`: Store, duplicate prevention, and substring recall across categories.
- `test_memory_lifecycle.metta`: Updating, superseding (`active` -> `superseded`), soft deleting, and history logging.
- `test_memory_consolidation.metta`: Short-term promotion to long-term, episodic event logging.
- `test_memory_persistence_process1.metta` & `test_memory_persistence_process2.metta`: Verified two independent process restarts loading and querying persisted disk files.
- `test_malformed_record_resilience.metta`: Verified recovery from corrupted syntax lines and complete rejection of code injection attempts.
- `test_memory_agent_loop_mocked.metta`: Multi-turn mocked loop executing `remember` and `recall` actions.
- `test_memory_live_agent.metta`: End-to-end live multi-turn cognitive cycle with Google Gemini remembering facts and answering follow-up queries using recalled memory.
