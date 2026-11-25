# PeTTa Agentic AI Framework — Project Notes (Competition Edition)

## Architecture Decisions

**PeTTa is the entire agent brain.** All cognition, reasoning, planning, action validation, tool dispatch, memory orchestration, and adaptive learning run natively in PeTTa (SWI-Prolog + MeTTa). Python provides only: stateless LLM/Search HTTP transport and the Streamlit UI presentation layer.

**Canonical 8-Action Protocol** (`answer`, `use_tool`, `use_skill`, `remember`, `recall`, `ask_user`, `finish`, `error`) — every LLM output is parsed into an S-expression and formally validated by `agent/action_validator.metta` before any execution occurs.

**AtomSpaces as cognitive state:** `&conversation` (working memory), `&long_term` (persistent facts), `&goal_space` (active goals), `&plan_space` (DAG tasks), `&feedback_space` (rewards), `&adaptation_space` (learned rules).

## Safety Design

**Destructive shell commands require genuine human approval.** The `is_destructive_command/2` predicate in `tools/system_primitives.pl` intercepts commands (`rm -rf`, `mkfs`, `dd`, `shutdown`, etc.) and suspends execution. Approval is only valid when a human writes to `memory/pending_approval.json` via the UI approval panel. **The model cannot self-approve**: the 3rd argument to `execute_shell_command_safe/4` is completely ignored. All decisions are recorded in `logs/command_audit.log`.

**Shell timeout:** `call_with_time_limit/2` enforces 15s default, kills the process, returns `[failure, "TIMEOUT: ..."]` as a readable observation — distinguishable from ordinary failure.

**Output capping:** Tool outputs exceeding 8KB are truncated to prevent context overflow.

**Path protection:** Write operations to `/etc`, `/usr`, `/bin`, `/sys`, `/proc`, `/dev`, `/root` are blocked unconditionally.

## Long-Task / Context Strategy

The context budget (16,000 chars ≈ 4,000 tokens) is enforced **every turn** via `build-agent-prompt-with-goal` in `agent/loop.metta`. The original goal is passed as `$original_goal` through all cognitive-step recursions, never lost. Dynamic context (older observations) is truncated intelligently when budget is exceeded. Core identity, protocol, tools, and current query are never dropped.

## ask_user Pause/Resume

When the agent emits `(action ask_user ...)`, PeTTa records `(ClarificationState awaiting ...)`, `(PendingGoal ...)`, and `(PendingPlan ...)` in `&conversation`. The controller detects this state on the next user input and calls `resume-after-clarification`, which injects the user's answer into the original goal context and re-runs the cognitive cycle. The resumed task continues from the correct point, not as a new unrelated task.

## Testing Approach

- **66 Python tests pass** (unit + integration, no network required)
- **3 live integration tests** auto-skip if no API key is configured (correctly conditional)
- **68 PeTTa MeTTa tests** cover all subsystems (run via `./scripts/run_petta_tests.sh`)
- Deterministic mock responses used in all network-free tests
- Real provider tests run when `GEMINI_API_KEY` / `OPENAI_API_KEY` are set

## How to Run

```bash
# 1. Clone and configure
git clone https://github.com/Tesfalegnp/Agentic-AI-With-PeTTa.git
cd Agentic-AI-With-PeTTa
cp .env.example .env
# Edit .env: set GEMINI_API_KEY (or OPENAI_API_KEY)

# 2. Install Python dependencies
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt

# 3. Run CLI agent
petta main.metta

# 4. Run Web UI
streamlit run ui/app.py

# 5. Run Python tests
pytest tests/ -v

# 6. Run PeTTa tests
./scripts/run_petta_tests.sh
```

## Known Limitations

- Web search without API keys falls back to DuckDuckGo HTML scraping (rate-limited).
- Very large outputs (>8KB) are truncated before reaching the agent context.
- Live integration tests require an LLM API key — skipped automatically without one.
