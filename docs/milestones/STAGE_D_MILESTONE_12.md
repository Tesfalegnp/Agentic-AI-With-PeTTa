# Stage D — Milestone 12: Adaptive Learning, Feedback & Agent Self-Improvement

## 1. Architectural Overview

Milestone 12 extends the PeTTa Agentic AI framework with declarative, bounded adaptive learning, feedback aggregation, rule lifecycle management, behavioral self-improvement, dynamic prompt guidance, and audit history.

The implementation strictly maintains the core framework boundary:

> **PeTTa owns ALL agent intelligence, feedback capture, parsing, classification, validation, aggregation, pattern detection, adaptation rule creation, lifecycle management, conflict resolution, ranking, retrieval, prompt integration, effectiveness evaluation, audit history, and disk persistence. Python serves strictly as an external LLM API transport bridge via Janus `py-call`.**

Furthermore, the **canonical 8-action protocol** is strictly preserved:
- `(action answer "<text>")`
- `(action ask_user "<question>")`
- `(action finish "<summary>")`
- `(action error "<type>" "<message>")`
- `(action use_tool <name> (<args>))`
- `(action use_skill <name> (<args>))`
- `(action remember <category> <content> <priority>)`
- `(action recall <category> <query> <limit>)`

**NO 9th action was introduced.** Feedback capture and adaptation operations occur deterministically through PeTTa subsystem operations, inspection commands, and lifecycle functions without expanding the canonical action space or polluting LLM action responses.

```
                      +------------------------------------------+
                      |         User Input / Feedback Event      |
                      +------------------------------------------+
                                           |
                                           v
                      +------------------------------------------+
                      |       Feedback Validator & Store         |
                      |       (agent/feedback_store.metta)       |
                      |            -> &feedback_space            |
                      +------------------------------------------+
                                           |
                                           v
                      +------------------------------------------+
                      |       Feedback Aggregation Engine        |
                      |    (agent/feedback_aggregation.metta)    |
                      |   Weighted Scoring & Threshold Checks    |
                      +------------------------------------------+
                                           |
                                           v
                      +------------------------------------------+
                      |       Adaptation Candidate Derivation    |
                      |      (agent/adaptation_engine.metta)     |
                      +------------------------------------------+
                                           |
                                           v
                      +------------------------------------------+
                      |       Adaptation Validator               |
                      |    (agent/adaptation_validator.metta)    |
                      |    Bounded Vocabulary & Conflict Check   |
                      +------------------------------------------+
                                           |
                                           v
                      +------------------------------------------+
                      |       Adaptation Registry & Space        |
                      |    (agent/adaptation_registry.metta)     |
                      |          -> &adaptation_space            |
                      +------------------------------------------+
                                           |
                   +-----------------------+-----------------------+
                   |                                               |
                   v                                               v
+--------------------------------------+       +--------------------------------------+
|     Evaluation Subsystem & Review    |       |      Prompt Integration & Conflict   |
|   (agent/adaptation_evaluation.metta)|       |      (agent/adaptation_conflict.metta|
|      -> &adaptation_eval_space       |       |            agent/prompt.metta)       |
+--------------------------------------+       +--------------------------------------+
                   |                                               |
                   v                                               v
+--------------------------------------+       +--------------------------------------+
|       Audit History Subsystem        |       |        Cognitive Loop Execution      |
|    (agent/adaptation_history.metta)  |       |        (Current Turn Takes Override) |
|       -> &adaptation_history         |       +--------------------------------------+
+--------------------------------------+
                   |
                   v
+--------------------------------------+
|        Disk-Backed Persistence       |
|  (agent/adaptation_persistence.metta)|
|          -> memory/*.tsv             |
+--------------------------------------+
```

---

## 2. Dedicated AtomSpaces & Schemas

Four distinct AtomSpaces are established to ensure strict isolation, clean querying, and independent lifecycles:

### A. Feedback Space (`&feedback_space`)
Stores raw and validated feedback records:
```scheme
(FeedbackRecord $id $category $polarity $target_type $target_id $text $context_id $source $weight $timestamp $status)
```
- `$id`: Unique identifier string (e.g. `"fb_1"`).
- `$category`: Validated feedback category (`answer_quality`, `verbosity`, `accuracy`, `tool_usage`, `skill_usage`, `planning_quality`, `task_completion`, `format_preference`, `clarification_quality`, `explanation_detail`).
- `$polarity`: `positive`, `negative`, `correction`, `neutral`.
- `$target_type`: `answer`, `tool`, `skill`, `plan`, `general`.
- `$target_id`: Identifier of the target or `none`.
- `$text`: Normalized text feedback string.
- `$context_id`: Interaction/query context string.
- `$source`: `explicit_user` (weight 1.0) or `inferred_signal` (weight 0.5).
- `$weight`: Floating-point numeric weight.
- `$timestamp`: Integer epoch or ISO timestamp.
- `$status`: `active`, `superseded`, `archived`.

### B. Adaptation Space (`&adaptation_space`)
Stores behavioral adaptation rules:
```scheme
(AdaptationRule $id $category $description $condition $recommendation $supporting_evidence $score $confidence $created $updated $status)
```
- `$id`: Unique identifier string (e.g. `"adapt_1"`).
- `$category`: Validated adaptation category (`verbosity`, `format_preference`, `explanation_detail`, `tool_preference`, `skill_preference`, `planning_preference`, `clarification_preference`).
- `$description`: Human-readable summary of the adaptation.
- `$condition`: Scope trigger symbol (`all_queries`, `math_queries`, `code_queries`, `analysis_queries`).
- `$recommendation`: Bounded behavioral recommendation symbol (`prefer_concise`, `prefer_detailed`, `include_calculations`, `omit_calculations`, `prefer_bullet_format`, `prefer_plain_text`, `prefer_json_format`, `avoid_markdown_table`, `prefer_tool_execution`, `prefer_skill_execution`, `ask_clarification_early`).
- `$supporting_evidence`: List of feedback IDs providing justification.
- `$score`: Cumulative weighted support score.
- `$confidence`: Confidence level ($0.0 \le c \le 1.0$).
- `$created`: Creation timestamp.
- `$updated`: Last update timestamp.
- `$status`: `candidate`, `active`, `suspended`, `disabled`, `superseded`.

### C. Adaptation History Space (`&adaptation_history`)
Stores an append-only audit trail of all lifecycle events:
```scheme
(AdaptationHistoryRecord $id $action_type $rule_id $details $timestamp)
```
- `$action_type`: `rule_created`, `rule_activated`, `rule_suspended`, `rule_disabled`, `rule_superseded`, `rule_restored`, `rule_evaluated`, `rule_reactivated`.

### D. Adaptation Evaluation Space (`&adaptation_eval_space`)
Tracks rule efficacy and outcome statistics:
```scheme
(AdaptationEvalRecord $rule_id $applications $positive_outcomes $negative_outcomes $last_applied $eval_status)
```
- `$applications`: Total number of times rule was included in active prompt context.
- `$positive_outcomes`: Number of positive follow-up feedback events.
- `$negative_outcomes`: Number of negative follow-up feedback events.
- `$last_applied`: Timestamp of most recent application.
- `$eval_status`: `insufficient_evidence`, `effective`, `neutral`, `review_needed`, `ineffective`.

---

## 3. Feedback Ingestion, Validation & Aggregation

### Parameter Validation & Text Sanitization
The feedback ingestion pipeline validates each parameter against allowlisted enumerations via deterministic `case` matching in `agent/adaptation_types.metta`.
Feedback text is normalized using `agent/adaptation_io.pl:clean_feedback_text/2`:
- Leading/trailing whitespace is trimmed.
- Text is converted to lowercase for comparison.
- Control characters and newlines are sanitized into space-separated clean strings.

### Deduplication
To prevent feedback spamming, identical feedback (same category, target, and cleaned text within the same context) is recognized as duplicate and returns `(FeedbackDuplicate $existing_id)`.

### Aggregation Formulas
Aggregation across feedback events is computed in `agent/adaptation_io.pl:aggregate_feedback_in_space/3`:
1. **Polarity Scoring:**
   $$\text{Score}(\text{positive}) = +1.0$$
   $$\text{Score}(\text{negative}) = -1.0$$
   $$\text{Score}(\text{correction}) = -1.5$$
   $$\text{Score}(\text{neutral}) = 0.0$$
2. **Source Weighting:**
   $$\text{Weight}(\text{explicit\_user}) = 1.0$$
   $$\text{Weight}(\text{inferred\_signal}) = 0.5$$
3. **Cumulative Weighted Score:**
   $$S = \sum_{i=1}^N \text{Weight}_i \times \text{Score}_i$$
4. **Evidence Threshold Criteria:**
   A candidate pattern requires either:
   - $N_{\text{events}} \ge 2$ independent feedback events, or
   - Cumulative support score $|S| \ge 2.0$.
5. **Contradiction Detection:**
   If both positive and negative/correction feedback exist such that $N_{\text{pos}} \ge 1 \land N_{\text{neg}} \ge 1$ and $|N_{\text{pos}} - N_{\text{neg}}| \le 1$, the subsystem flags a contradiction (`contradictory = true`). Any attempt to derive an adaptation rule from contradictory feedback is rejected (`CandidateRejected ContradictoryFeedback`).

---

## 4. Adaptation Lifecycle State Machine

The adaptation rule lifecycle is strictly governed by state transitions:

```
                  +--------------+
                  |  Feedback    |
                  +--------------+
                         |
                         v (recurring pattern meets threshold)
                  +--------------+
                  |  Candidate   |
                  +--------------+
                         |
                         v (adaptation-activate)
                  +--------------+
    +------------>|    Active    |<------------+
    |             +--------------+             |
    |               |          |               |
(restore)   (suspend)      (disable)       (restore)
    |               v          v               |
    |      +-----------+   +----------+        |
    +------| Suspended |   | Disabled |--------+
           +-----------+   +----------+
                 |
                 v (new rule with higher score)
           +------------+
           | Superseded |
           +------------+
```

1. **`candidate`**: Generated when evidence threshold is reached; inactive until activated.
2. **`active`**: Currently injected into prompt context for matching queries.
3. **`suspended`**: Temporarily deactivated due to conflicting instructions or negative evaluation review flags.
4. **`disabled`**: Explicitly turned off by the user via inspection controls.
5. **`superseded`**: Replaced by an updated or more specific rule.

---

## 5. Conflict Resolution & Instruction Precedence

A fundamental safety guarantee of the framework is that:

> **Direct User Instruction in the Current Turn ALWAYS overrides learned adaptations.**

### Instruction Override Logic (`agent/adaptation_conflict.metta`)
When a user query contains explicit instructions contradictory to an active rule:
- `prefer_concise` vs *"explain in detail"*, *"be thorough"*, *"detailed explanation"*, *"step by step"*
- `prefer_detailed` vs *"be brief"*, *"concise"*, *"short summary"*, *"tldr"*
- `avoid_markdown_table` vs *"in a table"*, *"tabular format"*, *"table"*
- `prefer_bullet_format` vs *"paragraph"*, *"plain text"*
- `prefer_tool_execution` vs *"do not use tools"*, *"without tools"*

`check-query-adaptation-conflict` identifies the conflict, logs a history event, and suppresses the adaptation guidance from the prompt. The LLM receives the user's fresh, explicit directive unhindered.

### Internal Rule Conflict Prevention
When creating or activating a rule, `detect_adaptation_rule_conflicts_in_space/2` checks against all currently active rules. An opposing recommendation (e.g. activating `prefer_detailed` while `prefer_concise` is active) causes validation failure `(ValidationFailed OpposingActiveRuleExists)` unless the existing rule is first suspended or superseded.

---

## 6. Evaluation Subsystem & Effectiveness Review

The evaluation engine in `agent/adaptation_evaluation.metta` tracks every application of an active rule:
1. `evaluation-record-application`: Increments the rule application counter whenever it is formatted into an LLM prompt.
2. `evaluation-record-outcome`: Records subsequent user feedback following an adaptation's application.
3. **Status Computation:**
   - `< 2` applications: `insufficient_evidence`
   - Positive feedback $\ge 70\%$: `effective`
   - Negative feedback $\ge 60\%$ with $\ge 2$ negatives: `review_needed` / `ineffective`
4. **Automated Review Flagging:**
   When an adaptation receives repeated negative feedback, `evaluation-should-review` triggers, allowing the cognitive loop or controller to automatically suspend the underperforming adaptation (`adaptation-suspend`) and log an audit entry.

---

## 7. Context Budget Integration

Learned preferences must not crowd out essential instructions or exceed context limits. `agent/context_budget.metta` provides `enforce-context-budget-with-adaptation`:
- Standard budget: Formats relevant active adaptation rules under `[LEARNED USER PREFERENCES & BEHAVIORAL ADAPTATIONS]`.
- Tight budget constraint: When total context budget is low, adaptation guidance is gracefully omitted while strictly guaranteeing that the mandatory core agent identity, instructions, and user query are preserved intact.

---

## 8. Disk Persistence & Recovery

All four AtomSpaces persist cleanly to disk in tab-separated value (TSV) format under `memory/`:
- `memory/feedback_store.tsv`: Raw feedback records.
- `memory/adaptation_rules.tsv`: Behavioral adaptation rules.
- `memory/adaptation_history.tsv`: Audit event logs.
- `memory/adaptation_evals.tsv`: Application and evaluation statistics.

Functions provided:
- `(adaptation-save-to-disk)`: Exports all in-memory spaces to TSV.
- `(adaptation-load-from-disk)`: Restores records into corresponding spaces on system startup.
- `(adaptation-clear-disk)`: Safely resets persistent files to clean empty headers.

---

## 9. Safety Boundaries & Guardrails

The learning subsystem is strictly bounded:
1. **Declarative Parameter Space Only:** Adaptations cannot generate executable code, modify Prolog clauses, or alter MeTTa function definitions dynamically.
2. **Allowlisted Recommendations:** Only pre-approved behavioral tokens from `is-valid-adaptation-recommendation` can be recommended.
3. **No Safety Bypass:** Adaptations cannot disable tool validation, bypass safety boundaries, or modify system identity.
4. **Auditability & User Control:** Full inspection (`adaptation-inspect`), manual disablement (`adaptation-disable`), and activation controls (`adaptation-activate`) are provided for complete human oversight.

---

## 10. Verification & Test Matrix

All tests passed with zero failures across unit, integration, and regression suites:

| Suite | File | Tests / Scenarios | Result |
| :--- | :--- | :--- | :--- |
| **Python Unit Tests** | `tests/test_*.py` | 35 Tests | **100% PASSED** ✅ |
| **Foundation Tests** | `tests/foundation/test_petta_fundamentals.metta` | 5 Tests | **100% PASSED** ✅ |
| **Protocol Tests** | `tests/protocol/test_action_parsing.metta` | 5 Tests | **100% PASSED** ✅ |
| **Interop Tests** | `tests/interop/test_*.metta` | 3 Suites | **100% PASSED** ✅ |
| **Agent Tests** | `tests/agent/test_*.metta` | 4 Suites | **100% PASSED** ✅ |
| **Tool Tests** | `tests/tools/test_*.metta` | 5 Suites | **100% PASSED** ✅ |
| **Skill Tests** | `tests/skills/test_*.metta` | 7 Suites | **100% PASSED** ✅ |
| **Memory Tests** | `tests/memory/test_*.metta` | 12 Suites | **100% PASSED** ✅ |
| **Planning Tests** | `tests/planning/test_*.metta` | 9 Suites | **100% PASSED** ✅ |
| **Adaptation Feedback Store** | `tests/adaptation/test_feedback_store.metta` | 8 Tests | **100% PASSED** ✅ |
| **Adaptation Aggregation** | `tests/adaptation/test_feedback_aggregation.metta` | 5 Tests | **100% PASSED** ✅ |
| **Adaptation Registry** | `tests/adaptation/test_adaptation_registry.metta` | 6 Tests | **100% PASSED** ✅ |
| **Adaptation Validator** | `tests/adaptation/test_adaptation_validator.metta` | 5 Tests | **100% PASSED** ✅ |
| **Adaptation Lifecycle** | `tests/adaptation/test_adaptation_lifecycle.metta` | 5 Tests | **100% PASSED** ✅ |
| **Adaptation Conflict** | `tests/adaptation/test_adaptation_conflict.metta` | 5 Tests | **100% PASSED** ✅ |
| **Adaptation Evaluation** | `tests/adaptation/test_adaptation_evaluation.metta` | 5 Tests | **100% PASSED** ✅ |
| **Adaptation History** | `tests/adaptation/test_adaptation_history.metta` | 3 Tests | **100% PASSED** ✅ |
| **Adaptation Persistence** | `tests/adaptation/test_adaptation_persistence.metta` | 4 Tests | **100% PASSED** ✅ |
| **Adaptation Prompt & Budget**| `tests/adaptation/test_adaptation_prompt_integration.metta` | 5 Tests | **100% PASSED** ✅ |
| **Live Integration Suite** | `tests/integration/test_adaptation_live.metta` | Scenarios A–G (Live Gemini) | **100% PASSED** ✅ |
