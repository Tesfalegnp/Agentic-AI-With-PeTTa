"""
STAGE D - MILESTONE 13: PeTTa Agentic AI Interactive Web UI
File: ui/app.py
Interactive Chat, Live Execution Progress, Agent Transparency & Project Demonstration.
"""

import sys
import os
from pathlib import Path

# Add project root to path
PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

import streamlit as st
from ui.agent_client import PeTTAAgentClient
from ui.event_protocol import AgentEvent, AgentExecutionResult, STAGE_ICONS
from ui.styles import CUSTOM_CSS

# Page configuration
st.set_page_config(
    page_title="PeTTa Agentic AI Framework",
    page_icon="🤖",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Inject custom CSS
st.markdown(CUSTOM_CSS, unsafe_allow_html=True)

# Initialize Agent Client
if "agent_client" not in st.session_state:
    st.session_state.agent_client = PeTTAAgentClient(str(PROJECT_ROOT))

# Initialize conversation history in session state
if "messages" not in st.session_state:
    st.session_state.messages = []

# Initialize telemetry history per turn
if "turn_telemetry" not in st.session_state:
    st.session_state.turn_telemetry = {}

client: PeTTAAgentClient = st.session_state.agent_client
system_status = client.get_system_status()


# =============================================================================
# SIDEBAR: System Status, Capabilities & Controls
# =============================================================================
with st.sidebar:
    st.markdown("### 🤖 Framework Runtime")
    st.markdown(
        f"""
        <div class="metric-box">
            <h4>Runtime Engine</h4>
            <p>{system_status['runtime']}</p>
        </div>
        <div class="metric-box">
            <h4>LLM Provider</h4>
            <p>{system_status['llm_provider']} <span style="font-size:0.8rem; font-weight:normal; color:#64748b;">({system_status['configured_model']})</span></p>
        </div>
        """,
        unsafe_allow_html=True
    )

    st.markdown("---")
    st.markdown("### 📊 Subsystem Status")
    col_m1, col_m2 = st.columns(2)
    with col_m1:
        st.metric("Memory Records", system_status["memory_records_count"])
    with col_m2:
        st.metric("Active Adaptations", system_status["active_adaptations_count"])

    st.markdown("---")
    st.markdown("### 🛠️ Available Tools")
    for t in system_status["tools"]:
        st.markdown(f"**`{t['name']}`** — {t['description']}")

    st.markdown("### ⚡ Available Skills")
    for s in system_status["skills"]:
        st.markdown(f"**`{s['name']}`** ({s['steps']} steps) — {s['description']}")

    st.markdown("---")
    st.markdown("### 🎯 Active Learned Preferences")
    if system_status["active_adaptations"]:
        for a in system_status["active_adaptations"]:
            st.info(f"**{a['category']}**: {a['recommendation']}\n\n*{a['description']}*")
    else:
        st.caption("No active adaptation rules stored yet. Submit feedback to train behavioral preferences.")

    st.markdown("---")
    st.markdown("### ⚙️ Session Controls")
    if st.button("🗑️ Clear Conversation", use_container_width=True):
        client.clear_conversation()
        st.session_state.messages = []
        st.session_state.turn_telemetry = {}
        st.rerun()

    # Technical Architecture Expander for Evaluators
    with st.expander("🏛️ Architecture Details (Evaluator Inspection)"):
        st.markdown("""
        **Separation of Responsibilities:**
        - **PeTTa Runtime (SWI-Prolog + MeTTa):** Owns all agent intelligence, cognitive loop, action validation, planning, dependency DAG scheduling, tools, skills, long-term memory, and adaptive learning.
        - **Python Layer:** Strictly UI presentation (Streamlit) and external LLM API transport via Janus `py-call`.
        - **Protocol:** Canonical 8-action protocol strictly preserved (`answer`, `ask_user`, `finish`, `error`, `use_tool`, `use_skill`, `remember`, `recall`).
        - **Telemetry:** Real-time observational JSONL events emitted natively by PeTTa during execution.
        """)


# =============================================================================
# MAIN AREA: Header & Welcome
# =============================================================================
st.markdown("""
<div class="main-header">
    <span class="arch-badge">Academic Demonstration</span>
    <span class="arch-badge" style="background-color:#10b981;">PeTTa Native Intelligence</span>
    <h1>PeTTa Agentic AI Assistant</h1>
    <p>Autonomous cognitive architecture with goal-driven planning, tool/skill orchestration, disk-backed persistent memory, and adaptive self-improvement.</p>
</div>
""", unsafe_allow_html=True)


# =============================================================================
# EVALUATOR DEMONSTRATIONS (7 MANDATORY SCENARIOS)
# =============================================================================
st.markdown("### 🎯 Evaluator Demonstrations (Ready-to-Run)")
st.caption("Select any evaluator scenario below to preview the exact prompt, inspect agent telemetry, and follow live execution:")

demo_tabs = st.tabs([
    "1. Simple File Task",
    "2. Web Research & Calc",
    "3. Long-Running (20+ Turns)",
    "4. Clarification Flow",
    "5. Failure Recovery",
    "6. Sequential Session",
    "7. DAG Planning"
])

quick_query = None

with demo_tabs[0]:
    st.markdown("**Scenario:** Creates a file on disk, reads back its content, and verifies integrity.")
    p1 = "Write 'PeTTa Agent operational status: verified' to 'status.txt' then read and verify it."
    st.code(p1, language="text")
    if st.button("🚀 Run Scenario 1: File Verification", key="btn_s1"):
        quick_query = p1

with demo_tabs[1]:
    st.markdown("**Scenario:** Searches current laptop options, compares specs, and calculates total price with tax.")
    p2 = "Research three current options for a suitable laptop for a CS student, compare their prices and specs, and calculate total price with 10% tax."
    st.code(p2, language="text")
    if st.button("🚀 Run Scenario 2: Web Research & Calculation", key="btn_s2"):
        quick_query = p2

with demo_tabs[2]:
    st.markdown("**Scenario:** Executes a 22-turn continuous recursive computation chain while preserving working memory context.")
    p3 = "Execute a continuous 22-step iterative calculation pipeline incrementing an accumulator and recording each turn."
    st.code(p3, language="text")
    if st.button("🚀 Run Scenario 3: 20+ Turn Execution", key="btn_s3"):
        quick_query = p3

with demo_tabs[3]:
    st.markdown("**Scenario:** Intentionally ambiguous request where the agent detects missing information and pauses to ask for clarification.")
    p4 = "Find the best option for my project and calculate the expected cost."
    st.code(p4, language="text")
    if st.button("🚀 Run Scenario 4: Clarification Flow", key="btn_s4"):
        quick_query = p4

with demo_tabs[4]:
    st.markdown("**Scenario:** Attempts a forbidden operation (or division by zero) and demonstrates graceful failure observation and recovery.")
    p5 = "Calculate 100 divided by 0, and if that fails, calculate 100 divided by 4 instead."
    st.code(p5, language="text")
    if st.button("🚀 Run Scenario 5: Failure Recovery", key="btn_s5"):
        quick_query = p5

with demo_tabs[5]:
    st.markdown("**Scenario:** Sequential execution of multiple distinct tasks in one session without restarting the agent process.")
    p6 = "Remember that I prefer python, then calculate 50 * 12, then read the project license file."
    st.code(p6, language="text")
    if st.button("🚀 Run Scenario 6: Sequential Multi-Task", key="btn_s6"):
        quick_query = p6

with demo_tabs[6]:
    st.markdown("**Scenario:** Decomposes complex request into a dependency-aware Directed Acyclic Graph (DAG) with visual task transitions.")
    p7 = "Create a multi-step workflow to analyze the text 'PeTTa combines formal symbolic reasoning with neural language models', count its words, and compute the square of that count."
    st.code(p7, language="text")
    if st.button("🚀 Run Scenario 7: DAG Planning", key="btn_s7"):
        quick_query = p7

st.markdown("---")


# =============================================================================
# CHAT HISTORY PRESENTATION
# =============================================================================
for idx, msg in enumerate(st.session_state.messages):
    with st.chat_message(msg["role"]):
        st.markdown(msg["content"])

        # If assistant message, display associated telemetry & feedback
        if msg["role"] == "assistant":
            turn_id = msg.get("turn_id", idx)
            events = st.session_state.turn_telemetry.get(turn_id, [])
            tasks = msg.get("tasks", [])

            # Expandable telemetry inspection
            if events or tasks:
                with st.expander("🔍 Live Execution Telemetry & Plan Inspection"):
                    if tasks:
                        st.markdown("##### 📋 Goal-Driven Plan Tasks:")
                        for t in tasks:
                            badge_class = f"badge-{t.status}"
                            st.markdown(
                                f"""
                                <div class="task-card">
                                    <div style="display:flex; justify-content:space-between; align-items:center;">
                                        <strong>Task {t.task_id} ({t.name})</strong>
                                        <span class="{badge_class}">{t.status.upper()}</span>
                                    </div>
                                    <p style="margin:4px 0; font-size:0.85rem; color:#64748b;">Executor: {t.task_type} | Args: <code>{t.args}</code></p>
                                    {"<p style='margin:2px 0; font-size:0.85rem; color:#0f172a;'>Result: <code>" + str(t.result) + "</code></p>" if t.result else ""}
                                </div>
                                """,
                                unsafe_allow_html=True
                            )

                    if events:
                        st.markdown("##### ⏱️ Real-Time Execution Timeline:")
                        for ev in events:
                            st.markdown(f"**{ev.formatted_time}** {ev.icon} `{ev.stage}`: {ev.message}")
                            if ev.details:
                                st.caption(f"Details: `{ev.details}`")

            # Feedback section
            fb_key = f"fb_{turn_id}"
            if not msg.get("feedback_submitted", False):
                st.markdown("---")
                f_cols = st.columns([1, 1, 4])
                with f_cols[0]:
                    if st.button("👍 Helpful", key=f"help_{turn_id}"):
                        client.submit_feedback(
                            category="answer_quality",
                            polarity="positive",
                            text="Response was helpful",
                            target_type="answer",
                            rating=1.0
                        )
                        msg["feedback_submitted"] = True
                        st.success("Feedback submitted to PeTTa AtomSpace!")
                        st.rerun()

                with f_cols[1]:
                    if st.button("👎 Not Helpful", key=f"unhelp_{turn_id}"):
                        client.submit_feedback(
                            category="answer_quality",
                            polarity="negative",
                            text="Response was not helpful or verbose",
                            target_type="answer",
                            rating=-1.0
                        )
                        msg["feedback_submitted"] = True
                        st.warning("Feedback submitted to PeTTa AtomSpace!")
                        st.rerun()


# =============================================================================
# INPUT & EXECUTION HANDLING
# =============================================================================
user_query = st.chat_input("Ask a question, request a calculation, or submit a multi-step task...")
if quick_query:
    user_query = quick_query

if user_query:
    # 1. Render user message
    st.session_state.messages.append({"role": "user", "content": user_query})
    with st.chat_message("user"):
        st.markdown(user_query)

    # 2. Render live agent execution progress
    turn_id = len(st.session_state.messages)
    collected_events = []

    with st.chat_message("assistant"):
        status_box = st.status("🧠 PeTTa Cognitive Runtime Initializing...", expanded=True)
        event_placeholder = status_box.empty()

        # Run streaming execution
        stream_gen = client.execute_query_stream(user_query, timeout_seconds=120)

        execution_result = None
        for item in stream_gen:
            if isinstance(item, AgentEvent):
                collected_events.append(item)
                # Update status container live
                status_box.update(label=f"{item.icon} {item.message}")
                # Render last 5 events in status box
                recent = collected_events[-6:]
                lines = [f"{ev.formatted_time} {ev.icon} **[{ev.stage}]** {ev.message}" for ev in recent]
                event_placeholder.markdown("\n\n".join(lines))
            elif isinstance(item, AgentExecutionResult):
                execution_result = item

        # If generator returned result via Return
        if execution_result is None:
            # Complete execution
            status_box.update(label="✅ PeTTa Execution Completed", state="complete", expanded=False)
            final_content = "Task finished."
            # Read last event or result file
            if collected_events:
                last_ev = collected_events[-1]
                if last_ev.event_type == "response_final":
                    final_content = last_ev.details if last_ev.details else last_ev.message
        else:
            final_content = execution_result.content
            if execution_result.is_success:
                status_box.update(label="✅ PeTTa Execution Completed Successfully", state="complete", expanded=False)
            else:
                status_box.update(label="❌ Agent Execution Error", state="error", expanded=True)

        st.markdown(final_content)

        # Store telemetry and message in session state
        st.session_state.turn_telemetry[turn_id] = collected_events
        st.session_state.messages.append({
            "role": "assistant",
            "content": final_content,
            "turn_id": turn_id,
            "tasks": execution_result.tasks if execution_result else [],
            "feedback_submitted": False
        })

    st.rerun()
