"""
PeTTa Agentic AI Framework — Competition-Ready Web UI (Full Dashboard Edition)
File: ui/app.py

Implements:
  - Live execution stage tracker (12 stages)
  - Real human approval panel for destructive commands
  - Clarification/pause-resume flow with task state display
  - Task and planning panel with step-by-step progress
  - Tool activity panel with timing and masked output
  - Memory and session panel
  - Full evaluator demonstration suite (7 scenarios)
  - Truthful agent status (completed / partial / blocked / failed / turn_limit)
"""

import sys
import os
import time
import json
from pathlib import Path
from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / ".env")

if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

import streamlit as st
from ui.agent_client import PeTTAAgentClient
from ui.event_protocol import AgentEvent, AgentExecutionResult, STAGE_ICONS, PlanTaskItem
from ui.styles import CUSTOM_CSS


def generate_plan_dag_dot(tasks: list, goal: str = "Cognitive Plan") -> str:
    """Generate Graphviz DOT diagram for plan execution graph."""
    lines = [
        'digraph PlanDAG {',
        '  rankdir=LR;',
        '  bgcolor="transparent";',
        '  node [fontname="sans-serif", fontsize=10, shape=box, style="rounded,filled", margin="0.2,0.1"];',
        '  edge [fontname="sans-serif", fontsize=9, color="#64748b", arrowsize=0.7, penwidth=1.5];',
    ]
    goal_label = (goal[:32] + "...") if len(goal) > 32 else goal
    lines.append(f'  __goal__ [label="🎯 {goal_label}", fillcolor="#1e293b", fontcolor="#ffffff", color="#6366f1", penwidth=2.0];')
    prev_node = '__goal__'
    for t in tasks:
        node_id = str(getattr(t, "task_id", "task")).replace("-", "_").replace(" ", "_")
        name = str(getattr(t, "name", getattr(t, "tool_or_skill", "task")))
        status = str(getattr(t, "status", "pending")).lower()
        if status == "completed":
            fill = "#10b981"
            font = "#ffffff"
            border = "#059669"
            badge = "✅ COMPLETED"
        elif status in ("running", "ready"):
            fill = "#f59e0b"
            font = "#1e293b"
            border = "#d97706"
            badge = "⚙️ RUNNING"
        elif status == "failed":
            fill = "#ef4444"
            font = "#ffffff"
            border = "#b91c1c"
            badge = "❌ FAILED"
        elif status in ("blocked", "awaiting_approval"):
            fill = "#0ea5e9"
            font = "#ffffff"
            border = "#0284c7"
            badge = "🔒 BLOCKED"
        else:
            fill = "#334155"
            font = "#cbd5e1"
            border = "#475569"
            badge = "⏳ PENDING"

        clean_name = name.replace('"', '\\"')
        lines.append(f'  {node_id} [label="{node_id}: {clean_name}\\n[{badge}]", fillcolor="{fill}", fontcolor="{font}", color="{border}", penwidth=1.5];')
        lines.append(f'  {prev_node} -> {node_id};')
        prev_node = node_id
    lines.append('}')
    return "\n".join(lines)

# ==============================================================================
# Page Configuration
# ==============================================================================
st.set_page_config(
    page_title="PeTTa Agentic AI — Competition Dashboard",
    page_icon="🤖",
    layout="wide",
    initial_sidebar_state="expanded"
)
st.markdown(CUSTOM_CSS, unsafe_allow_html=True)

# ==============================================================================
# Session State Initialization
# ==============================================================================
if "agent_client" not in st.session_state:
    st.session_state.agent_client = PeTTAAgentClient(str(PROJECT_ROOT))
if "messages" not in st.session_state:
    st.session_state.messages = []
if "turn_telemetry" not in st.session_state:
    st.session_state.turn_telemetry = {}
if "task_number" not in st.session_state:
    st.session_state.task_number = 0
if "pending_approval" not in st.session_state:
    st.session_state.pending_approval = None
if "awaiting_clarification" not in st.session_state:
    st.session_state.awaiting_clarification = False
if "clarification_question" not in st.session_state:
    st.session_state.clarification_question = ""

client: PeTTAAgentClient = st.session_state.agent_client
system_status = client.get_system_status()

# Check if approval is currently pending
pending_approval = client.get_pending_approval_request()
if pending_approval:
    st.session_state.pending_approval = pending_approval

# ==============================================================================
# SIDEBAR: System Dashboard
# ==============================================================================
with st.sidebar:
    # Header
    st.markdown("""
    <div style="background: linear-gradient(135deg,#1e293b,#0f172a);
         padding:1rem 1.2rem; border-radius:10px; margin-bottom:1rem;">
      <h3 style="color:#f8fafc;margin:0;font-size:1.1rem;">🤖 PeTTa Agent Runtime</h3>
      <p style="color:#94a3b8;margin:0.3rem 0 0;font-size:0.8rem;">
        SWI-Prolog + MeTTa Cognitive Engine
      </p>
    </div>
    """, unsafe_allow_html=True)

    # Provider & Model Status
    api_ok = system_status["api_key_configured"]
    api_color = "#10b981" if api_ok else "#f59e0b"
    api_label = "✅ API Key Set" if api_ok else "⚠️ No API Key"

    st.markdown(f"""
    <div class="metric-box">
      <div style="display:flex;justify-content:space-between;align-items:center;">
        <span style="font-weight:600;">{system_status['llm_provider']}</span>
        <span style="color:{api_color};font-size:0.75rem;">{api_label}</span>
      </div>
      <div style="color:#94a3b8;font-size:0.8rem;">{system_status['configured_model']}</div>
    </div>
    """, unsafe_allow_html=True)

    # Provider & API Key Configuration Settings (Live Evaluator Switcher)
    with st.expander("⚙️ LLM Provider & Key Settings", expanded=False):
        provider_options = ["gemini", "openai", "deepseek", "generic_openai"]
        current_p = os.environ.get("LLM_PROVIDER", "gemini").lower().strip()
        idx = provider_options.index(current_p) if current_p in provider_options else 0
        selected_provider = st.selectbox("Select LLM Provider", provider_options, index=idx, key="sb_provider")

        key_env_var = {
            "gemini": "GEMINI_API_KEY",
            "openai": "OPENAI_API_KEY",
            "deepseek": "DEEPSEEK_API_KEY",
            "generic_openai": "GENERIC_API_KEY"
        }[selected_provider]

        current_val = os.environ.get(key_env_var, "")
        new_key_input = st.text_input(
            f"{selected_provider.upper()} API Key",
            value=current_val,
            type="password",
            placeholder=f"Paste {selected_provider} key here...",
            key="sb_key_input"
        )

        # For generic_openai, allow customizing Base URL and Model name directly
        generic_url_val = os.environ.get("GENERIC_BASE_URL", "https://api.groq.com/openai/v1")
        generic_model_val = os.environ.get("GENERIC_MODEL", "qwen/qwen3.8-27b")
        if selected_provider == "generic_openai":
            generic_url_input = st.text_input("Generic Base URL", value=generic_url_val, key="sb_generic_url")
            generic_model_input = st.text_input("Generic Model Name", value=generic_model_val, key="sb_generic_model")

        col_save, col_clear = st.columns(2)
        with col_save:
            if st.button("💾 Apply Settings", use_container_width=True, type="primary"):
                os.environ["LLM_PROVIDER"] = selected_provider
                if new_key_input.strip():
                    os.environ[key_env_var] = new_key_input.strip()
                if selected_provider == "generic_openai":
                    if generic_url_input.strip():
                        os.environ["GENERIC_BASE_URL"] = generic_url_input.strip()
                    if generic_model_input.strip():
                        os.environ["GENERIC_MODEL"] = generic_model_input.strip()
                st.success(f"Applied {selected_provider.upper()}!")
                st.rerun()
        with col_clear:
            if st.button("🔄 Reload .env", use_container_width=True):
                load_dotenv(PROJECT_ROOT / ".env", override=True)
                st.rerun()

    # Memory & Adaptation Metrics
    col_m1, col_m2 = st.columns(2)
    with col_m1:
        st.metric("💾 Memories", system_status["memory_records_count"])
    with col_m2:
        st.metric("🎯 Rules", system_status["active_adaptations_count"])

    st.markdown("---")

    # === APPROVAL PANEL ===
    if st.session_state.pending_approval:
        pa = st.session_state.pending_approval
        st.markdown("""
        <div style="background:#7f1d1d;border:2px solid #ef4444;border-radius:8px;
             padding:1rem;margin-bottom:1rem;">
          <h4 style="color:#fca5a5;margin:0 0 0.5rem;">🔒 APPROVAL REQUIRED</h4>
          <p style="color:#fecaca;font-size:0.85rem;margin:0;">
            A shell command requires your explicit authorization before it can run.
          </p>
        </div>
        """, unsafe_allow_html=True)

        st.markdown(f"**Command:**\n```bash\n{pa.get('command','')}\n```")
        st.markdown(f"**Risk:** {pa.get('risk','Potentially destructive')}")
        st.warning("⚠️ This command will NOT run until you explicitly approve it.")

        col_a, col_s, col_d = st.columns(3)
        with col_a:
            if st.button("✅ APPROVE", type="primary", use_container_width=True):
                client.submit_approval_decision(
                    pa.get("command", ""),
                    pa.get("risk", ""),
                    "approved"
                )
                st.session_state.pending_approval = None
                st.success("Command approved! Resuming execution...")
                st.rerun()
        with col_s:
            if st.button("⏭️ SKIP", use_container_width=True):
                client.submit_approval_decision(
                    pa.get("command", ""),
                    pa.get("risk", ""),
                    "denied"
                )
                st.session_state.pending_approval = None
                st.info("Command skipped. Continuing task safely...")
                st.rerun()
        with col_d:
            if st.button("❌ DENY", use_container_width=True):
                client.submit_approval_decision(
                    pa.get("command", ""),
                    pa.get("risk", ""),
                    "denied"
                )
                st.session_state.pending_approval = None
                st.error("Command denied.")
                st.rerun()

        st.markdown("---")

    # === CLARIFICATION PANEL ===
    if st.session_state.awaiting_clarification:
        st.markdown("""
        <div style="background:#1e3a5f;border:2px solid #3b82f6;border-radius:8px;
             padding:1rem;margin-bottom:1rem;">
          <h4 style="color:#93c5fd;margin:0 0 0.5rem;">💬 CLARIFICATION NEEDED</h4>
          <p style="color:#bfdbfe;font-size:0.85rem;margin:0;">
            The agent has paused and is waiting for more information.
            Your task has been preserved.
          </p>
        </div>
        """, unsafe_allow_html=True)
        st.info(f"**Agent asks:** {st.session_state.clarification_question}")
        if st.button("🚫 Cancel Suspended Task", key="btn_cancel_clarify_sb", use_container_width=True):
            st.session_state.awaiting_clarification = False
            st.session_state.clarification_question = ""
            client.clear_conversation()
            st.warning("Suspended task cancelled.")
            st.rerun()
        st.caption("Type your answer in the chat box to resume the suspended task.")
        st.markdown("---")

    # Tools
    with st.expander("🛠️ Available Tools (10)", expanded=False):
        for t in system_status["tools"]:
            cat_color = {"math": "#10b981", "text": "#6366f1",
                         "system": "#f59e0b", "research": "#3b82f6"}.get(t["category"], "#64748b")
            st.markdown(
                f'<span style="color:{cat_color};font-weight:600;">`{t["name"]}`</span> — {t["description"]}',
                unsafe_allow_html=True
            )

    with st.expander("⚡ Available Skills (3)", expanded=False):
        for s in system_status["skills"]:
            st.markdown(f"**`{s['name']}`** ({s['steps']} steps) — {s['description']}")

    # Learned Preferences
    if system_status["active_adaptations"]:
        with st.expander("🎯 Learned Preferences", expanded=False):
            for a in system_status["active_adaptations"]:
                st.info(f"**{a['category']}**: {a['recommendation']}\n\n*{a['description']}*")

    # Audit Log
    audit_lines = client.get_recent_audit_log(10)
    if audit_lines:
        with st.expander("🔍 Command Audit Log", expanded=False):
            for line in audit_lines:
                st.code(line, language="text")

    st.markdown("---")

    # Architecture Details
    with st.expander("🏛️ Architecture (Evaluator)", expanded=False):
        st.markdown("""
**PeTTa is the agent brain.**

| Layer | Responsibility |
|-------|---------------|
| PeTTa Runtime | Cognitive loop, planning, tools, memory, learning |
| Python Bridge | LLM HTTP transport only (Gemini/OpenAI/DeepSeek) |
| Streamlit UI | Presentation + IPC gateway |

**Safety Model:**
- Destructive shell commands → human approval required
- Model cannot self-approve via output
- Approval IPC file written only by human via UI
- All commands logged to audit trail
        """)

    st.markdown("---")

    # Session Controls
    st.markdown("### ⚙️ Session Controls")
    col_s1, col_s2 = st.columns(2)
    with col_s1:
        if st.button("🗑️ Clear Chat", use_container_width=True):
            client.clear_conversation()
            client.clear_approval_request()
            st.session_state.messages = []
            st.session_state.turn_telemetry = {}
            st.session_state.task_number = 0
            st.session_state.pending_approval = None
            st.session_state.awaiting_clarification = False
            st.session_state.clarification_question = ""
            st.rerun()
    with col_s2:
        st.metric("Turn #", st.session_state.task_number)


# ==============================================================================
# MAIN HEADER
# ==============================================================================
st.markdown("""
<div class="main-header">
    <div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;">
        <span class="arch-badge">Weekly Hackaton Competition</span>
        <span class="arch-badge" style="background-color:#10b981;">Petta Agentic</span>
        <span class="arch-badge" style="background-color:#f59e0b;color:#1e293b;">Human-in-the-Loop Safety</span>
    </div>
    <h1>PeTTa Agentic AI Assistant</h1>
    <p>Autonomous cognitive architecture: symbolic reasoning, goal-driven planning,
       persistent AtomSpace memory, real tool execution, and adaptive learning.
       All intelligence lives natively in PeTTa (SWI-Prolog + MeTTa).
    </p>
</div>
""", unsafe_allow_html=True)


# ==============================================================================
# EVALUATOR DEMONSTRATION SUITE
# ==============================================================================
with st.expander("🎯 Evaluator Demonstrations — Click to Load & Run", expanded=False):
    st.caption("These are the 10 required evaluator scenarios. Click any button to send the query to the live agent.")

    demo_scenarios = [
        {
            "label": "1. Multi-Tool Task",
            "query": "Write the text 'Dataset: [10, 20, 30, 40, 50]' to /tmp/dataset.txt, then read it back, then calculate the sum: 10+20+30+40+50, and report all three results together.",
            "desc": "Tests write_file → read_file → calculator chain."
        },
        {
            "label": "2. Long Task (20+ Turns)",
            "query": "Execute an iterative accumulation pipeline and ask me again how many turns: start with accumulator=0, increment by 1 each turn using the calculator tool, store each intermediate result, and report the final value.",
            "desc": "Tests 22+ agent turns, context budget, goal preservation."
        },
        {
            "label": "3. Failure Recovery",
            "query": "Read the file /tmp/does_not_exist.txt, then if that fails recover by writing 'Recovered content' to /tmp/recovered.txt and confirm it was written.",
            "desc": "Tests missing file error → recovery → alternate path."
        },
        {
            "label": "4. Clarification & Resume",
            "query": "Analyze the data in my file.",
            "desc": "Ambiguous — agent should ask which file, then resume after user answers."
        },
        {
            "label": "5. Destructive Approval",
            "query": "Run the command: rm -rf /tmp/test_petta_safe",
            "desc": "Tests that the destructive command is blocked until human approves."
        },
        {
            "label": "6. Multiple Tasks (Session)",
            "query": "Task 1: Calculate 7 * 8. Task 2: What is the current time?",
            "desc": "Two tasks in one session — state isolation verified."
        },
        {
            "label": "7. Context Stress",
            "query": "Run the command 'ls /tmp' using run_command, then count the words in the output with word_counter, and write the count summary to /tmp/stress_test.txt.",
            "desc": "Tests large output handling and context compaction."
        },
        {
            "label": "8. Unknown Tool",
            "query": "Use the imaginary_tool to do something impossible.",
            "desc": "Tests that unknown tools return readable error observations."
        },
        {
            "label": "9. Web Research",
            "query": "Search the web for 'Python SWI-Prolog Janus bridge documentation' and summarize what you find.",
            "desc": "Tests web_search with provider fallback."
        },
        {
            "label": "10. Memory Persistence",
            "query": "Remember that my project is called 'PeTTa Competition 2026', then recall it back and confirm.",
            "desc": "Tests remember → recall → answer round-trip."
        },
    ]

    quick_query = None
    cols = st.columns(2)
    for i, scenario in enumerate(demo_scenarios):
        with cols[i % 2]:
            st.markdown(f"**{scenario['label']}**")
            st.caption(scenario["desc"])
            if st.button(f"▶ Run: {scenario['label']}", key=f"demo_{i}", use_container_width=True):
                quick_query = scenario["query"]


# ==============================================================================
# CONVERSATION HISTORY
# ==============================================================================
for msg in st.session_state.messages:
    with st.chat_message(msg["role"]):
        st.markdown(msg["content"])

        if msg["role"] == "assistant":
            turn_id = msg.get("turn_id", 0)
            events = st.session_state.turn_telemetry.get(turn_id, [])
            tasks = msg.get("tasks", [])
            completion_status = msg.get("completion_status", "")

            # Completion status badge
            status_colors = {
                "completed": "#10b981",
                "turn_limit": "#f59e0b",
                "failed": "#ef4444",
                "blocked": "#3b82f6",
                "awaiting_clarification": "#0ea5e9",
                "approval_required": "#f59e0b",
                "partial": "#8b5cf6"
            }
            status_labels = {
                "awaiting_clarification": "💬 AWAITING CLARIFICATION",
                "approval_required": "🔒 APPROVAL REQUIRED",
                "completed": "COMPLETED",
                "turn_limit": "TURN LIMIT",
                "failed": "FAILED",
                "blocked": "PAUSED",
                "partial": "PARTIAL"
            }
            if completion_status:
                sc = status_colors.get(completion_status, "#64748b")
                lbl = status_labels.get(completion_status, completion_status.upper())
                st.markdown(
                    f'<span style="background:{sc};color:white;padding:3px 10px;border-radius:6px;font-size:0.75rem;font-weight:600;letter-spacing:0.5px;">'
                    f'{lbl}</span>',
                    unsafe_allow_html=True
                )

            # Interactive Visual Reasoning & Plan Execution Graph (DAG)
            if tasks:
                with st.expander(f"🗺️ Visual Reasoning & Plan Execution Graph ({len(tasks)} steps)", expanded=True):
                    try:
                        dag_dot = generate_plan_dag_dot(tasks, goal="Execution Pipeline")
                        st.graphviz_chart(dag_dot, use_container_width=True)
                    except Exception as err:
                        st.caption(f"Graph renderer notice: {err}")

                    st.markdown("**Detailed Steps:**")
                    for t in tasks:
                        status_icon = {"completed": "✅", "failed": "❌",
                                       "running": "⚙️", "pending": "⏳",
                                       "blocked": "🔒", "ready": "⚡"}.get(t.status, "🔹")
                        task_name = getattr(t, "name", getattr(t, "tool_or_skill", "task"))
                        st.markdown(
                            f"{status_icon} **{t.task_id}**: `{task_name}` — {t.status}"
                        )

            # Execution timeline
            if events:
                with st.expander(f"⏱️ Execution Timeline ({len(events)} events)", expanded=False):
                    tool_events = [e for e in events if e.stage in ("tool", "skill")]
                    if tool_events:
                        st.markdown("**🛠️ Tool Activity:**")
                        for ev in tool_events:
                            st.markdown(
                                f"- `{ev.formatted_time}` {ev.icon} **{ev.event_type}**: {ev.message[:120]}"
                            )
                    st.markdown("**📊 Full Timeline:**")
                    for ev in events:
                        st.markdown(f"{ev.formatted_time} {ev.icon} `{ev.stage}`: {ev.message}")
                        if ev.details and len(ev.details) < 300:
                            st.caption(f"↳ {ev.details}")

            # Feedback
            if not msg.get("feedback_submitted", False):
                f_cols = st.columns([1, 1, 4])
                with f_cols[0]:
                    if st.button("👍", key=f"help_{turn_id}"):
                        client.submit_feedback("answer_quality", "positive",
                                               "Response was helpful", rating=1.0)
                        msg["feedback_submitted"] = True
                        st.success("Feedback → PeTTa AtomSpace!")
                        st.rerun()
                with f_cols[1]:
                    if st.button("👎", key=f"unhelp_{turn_id}"):
                        client.submit_feedback("answer_quality", "negative",
                                               "Response was not helpful", rating=-1.0)
                        msg["feedback_submitted"] = True
                        st.warning("Feedback → PeTTa AtomSpace!")
                        st.rerun()


# ==============================================================================
# EXECUTION STAGE TRACKER (12 Stages)
# ==============================================================================
EXECUTION_STAGES = [
    ("📥", "Task Received"),
    ("🎯", "Goal Understood"),
    ("📋", "Planning"),
    ("📐", "Context Prep"),
    ("🌐", "LLM Reasoning"),
    ("✅", "Action Validated"),
    ("🛠️", "Tool Execution"),
    ("🔍", "Observation"),
    ("🔄", "Recovery/Replan"),
    ("💾", "Memory Update"),
    ("✔️", "Completion Check"),
    ("💬", "Final Response"),
]


def render_stage_tracker(active_stage_idx: int):
    """Render the 12-stage live execution tracker."""
    cols = st.columns(len(EXECUTION_STAGES))
    for i, (icon, name) in enumerate(EXECUTION_STAGES):
        with cols[i]:
            if i < active_stage_idx:
                st.markdown(
                    f'<div style="text-align:center;color:#10b981;font-size:0.65rem;">'
                    f'{icon}<br><b>{name}</b></div>',
                    unsafe_allow_html=True
                )
            elif i == active_stage_idx:
                st.markdown(
                    f'<div style="text-align:center;color:#3b82f6;font-size:0.65rem;'
                    f'background:#1e3a5f;border-radius:4px;padding:2px;">'
                    f'{icon}<br><b>{name}</b></div>',
                    unsafe_allow_html=True
                )
            else:
                st.markdown(
                    f'<div style="text-align:center;color:#475569;font-size:0.65rem;">'
                    f'{icon}<br>{name}</div>',
                    unsafe_allow_html=True
                )


STAGE_EVENT_MAP = {
    "init": 0,
    "query_received": 0,
    "reasoning": 1,
    "planning": 2,
    "context": 3,
    "llm": 4,
    "action": 5,
    "tool": 6,
    "skill": 6,
    "observation": 7,
    "recovery": 8,
    "memory": 9,
    "verification": 10,
    "complete": 11,
}


def event_to_stage(ev: AgentEvent) -> int:
    return STAGE_EVENT_MAP.get(ev.stage.lower(), 1)


# ==============================================================================
# CHAT INPUT & EXECUTION HANDLER
# ==============================================================================
clarification_input = None
if st.session_state.awaiting_clarification:
    st.markdown(f"""
    <div style="background:#0f2b48;border:2px solid #38bdf8;border-radius:10px;padding:1.2rem;margin:1rem 0;">
      <div style="display:flex;align-items:center;gap:0.5rem;margin-bottom:0.5rem;">
        <span style="font-size:1.3rem;">💬</span>
        <h4 style="color:#f0f9ff;margin:0;font-size:1.1rem;">Clarification Required to Proceed</h4>
      </div>
      <p style="color:#bae6fd;margin:0 0 0.8rem;font-size:0.95rem;">
        <strong>Agent asks:</strong> {st.session_state.clarification_question}
      </p>
      <p style="color:#94a3b8;margin:0;font-size:0.8rem;">
        ℹ️ The task is paused and its active goal is preserved. Provide your answer below to resume execution.
      </p>
    </div>
    """, unsafe_allow_html=True)
    with st.form("clarification_form", clear_on_submit=True):
        ans_text = st.text_input("Your clarification response:", placeholder="e.g. Use the file /tmp/dataset.txt", key="form_ans")
        col_c_sub, col_c_canc = st.columns([2, 1])
        with col_c_sub:
            submitted = st.form_submit_button("▶ Submit & Resume Task", type="primary", use_container_width=True)
            if submitted and ans_text.strip():
                clarification_input = ans_text.strip()
        with col_c_canc:
            cancelled = st.form_submit_button("🚫 Cancel Task", use_container_width=True)
            if cancelled:
                st.session_state.awaiting_clarification = False
                st.session_state.clarification_question = ""
                client.clear_conversation()
                st.rerun()

user_query = st.chat_input(
    "Ask a question or enter a task..." if not st.session_state.awaiting_clarification
    else "Type your clarification answer here and press Enter..."
)
if clarification_input:
    user_query = clarification_input
elif quick_query and not user_query:
    user_query = quick_query

if user_query:
    st.session_state.task_number += 1
    task_num = st.session_state.task_number

    # Display user message
    st.session_state.messages.append({"role": "user", "content": user_query})
    with st.chat_message("user"):
        st.markdown(user_query)

    turn_id = len(st.session_state.messages)
    collected_events: list = []
    start_time = time.time()
    current_stage = 0

    with st.chat_message("assistant"):
        # Live stage tracker container
        stage_container = st.empty()
        stage_container.markdown("*Initializing PeTTa runtime...*")

        # Live status expander
        status_box = st.status("🧠 PeTTa Cognitive Runtime Active", expanded=True)
        event_placeholder = status_box.empty()
        tool_panel = status_box.empty()

        # Main execution
        stream_gen = client.execute_query_stream(user_query, timeout_seconds=120)
        execution_result = None

        for item in stream_gen:
            if isinstance(item, AgentEvent):
                collected_events.append(item)
                new_stage = event_to_stage(item)
                if new_stage > current_stage:
                    current_stage = new_stage

                # Update stage tracker
                with stage_container.container():
                    render_stage_tracker(current_stage)

                # Update status label
                status_box.update(label=f"{item.icon} [{item.stage}] {item.message[:90]}")

                # Update event log (last 6 events)
                recent = collected_events[-6:]
                lines = [
                    f"**{ev.formatted_time}** {ev.icon} `{ev.stage}` {ev.message}"
                    for ev in recent
                ]
                event_placeholder.markdown("\n\n".join(lines))

                # Dedicated tool panel
                tool_evs = [e for e in collected_events if e.stage in ("tool", "skill")]
                if tool_evs:
                    tool_lines = []
                    for te in tool_evs[-3:]:
                        elapsed = f"{te.timestamp - start_time:.1f}s"
                        tool_lines.append(
                            f"🛠️ `{te.event_type}` @ {elapsed} — {te.message[:80]}"
                        )
                    tool_panel.markdown("\n\n".join(tool_lines))

            elif isinstance(item, AgentExecutionResult):
                execution_result = item

        # Finalize stage tracker
        with stage_container.container():
            render_stage_tracker(11)

        elapsed = time.time() - start_time

        # Determine completion status
        completion_status = "completed"
        final_content = "Task completed."

        if execution_result:
            final_content = execution_result.content
            action = execution_result.action
            if "turn_limit" in final_content.lower() or action == "max_iterations_exceeded":
                completion_status = "turn_limit"
                status_box.update(
                    label=f"⚠️ Turn Limit Reached ({elapsed:.1f}s)",
                    state="error", expanded=True
                )
            elif action in ("error",):
                completion_status = "failed"
                status_box.update(
                    label=f"❌ Execution Error ({elapsed:.1f}s)",
                    state="error", expanded=True
                )
            elif action == "ask_user":
                completion_status = "awaiting_clarification"
                st.session_state.awaiting_clarification = True
                st.session_state.clarification_question = final_content
                status_box.update(
                    label=f"💬 Awaiting Clarification ({elapsed:.1f}s)",
                    state="running", expanded=True
                )
            elif execution_result.is_success:
                completion_status = "completed"
                status_box.update(
                    label=f"✅ Completed ({elapsed:.1f}s — {len(collected_events)} events)",
                    state="complete", expanded=False
                )
            else:
                completion_status = "failed"
                status_box.update(label=f"❌ Failed ({elapsed:.1f}s)", state="error", expanded=True)

            # Detect approval required from content
            if "APPROVAL_REQUIRED" in final_content:
                completion_status = "approval_required"
                # Parse command from content
                lines_c = final_content.split("\n")
                cmd_line = next((l for l in lines_c if "Command:" in l), "")
                risk_line = next((l for l in lines_c if "Risk:" in l), "")
                cmd = cmd_line.replace("Command:", "").strip()
                risk = risk_line.replace("Risk:", "").strip()
                if cmd:
                    client.set_pending_approval_request(cmd, risk)
                    st.session_state.pending_approval = {"command": cmd, "risk": risk, "decision": "pending"}
                status_box.update(
                    label=f"🔒 Approval Required — See Sidebar ({elapsed:.1f}s)",
                    state="running", expanded=True
                )
        else:
            if collected_events:
                last_ev = collected_events[-1]
                final_content = last_ev.details if last_ev.details else last_ev.message
                if last_ev.event_type == "timeout_error":
                    completion_status = "failed"
                    status_box.update(label="⏱️ Execution Timed Out", state="error", expanded=True)
                else:
                    status_box.update(label=f"✅ Done ({elapsed:.1f}s)", state="complete", expanded=False)

        # Resume if clarification was just answered
        if st.session_state.awaiting_clarification and execution_result:
            if execution_result.action != "ask_user":
                st.session_state.awaiting_clarification = False
                st.session_state.clarification_question = ""

        st.markdown(final_content)

        # Store in session
        st.session_state.turn_telemetry[turn_id] = collected_events
        tasks_list = execution_result.tasks if execution_result else []
        st.session_state.messages.append({
            "role": "assistant",
            "content": final_content,
            "turn_id": turn_id,
            "tasks": tasks_list,
            "completion_status": completion_status,
            "feedback_submitted": False
        })

    st.rerun()
