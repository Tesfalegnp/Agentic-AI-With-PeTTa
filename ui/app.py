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
# QUICK PROMPTS FOR EVALUATOR DEMO
# =============================================================================
st.markdown("##### 💡 Example Tasks for Evaluation:")
q_cols = st.columns(3)
quick_query = None

with q_cols[0]:
    if st.button("🔢 Calculate 45 * 12", use_container_width=True):
        quick_query = "Calculate 45 multiplied by 12."
    if st.button("🌍 Capital of France", use_container_width=True):
        quick_query = "What is the capital of France?"

with q_cols[1]:
    if st.button("📋 Multi-step Text Workflow", use_container_width=True):
        quick_query = "Create a multi-step workflow to analyze a piece of text."
    if st.button("📊 Text Metrics Analysis", use_container_width=True):
        quick_query = "Analyze this text and provide its word count and sentiment-style summary."

with q_cols[2]:
    if st.button("💾 Remember Preference", use_container_width=True):
        quick_query = "Remember that I prefer concise explanations."
    if st.button("🔍 Recall Stored Preferences", use_container_width=True):
        quick_query = "What user preferences do you have stored in memory?"


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
