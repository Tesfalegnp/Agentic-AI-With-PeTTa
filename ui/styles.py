"""
STAGE D - MILESTONE 13: UI Styling & Theme
File: ui/styles.py
CSS design for modern academic and enterprise agentic AI presentation.
"""

CUSTOM_CSS = """
<style>
/* Main Container & Font */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap');

html, body, [class*="css"] {
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
}

code, pre {
    font-family: 'JetBrains Mono', monospace !important;
}

/* Header Banner */
.main-header {
    background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
    color: #ffffff;
    padding: 1.5rem 2rem;
    border-radius: 12px;
    margin-bottom: 1.5rem;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    border: 1px solid #334155;
}

.main-header h1 {
    margin: 0;
    font-size: 1.8rem;
    font-weight: 700;
    letter-spacing: -0.02em;
    color: #f8fafc;
}

.main-header p {
    margin: 0.4rem 0 0 0;
    font-size: 0.95rem;
    color: #94a3b8;
}

/* Architecture Badge */
.arch-badge {
    display: inline-block;
    background-color: #3b82f6;
    color: #ffffff;
    font-size: 0.75rem;
    font-weight: 600;
    padding: 0.2rem 0.6rem;
    border-radius: 9999px;
    margin-right: 0.5rem;
    text-transform: uppercase;
    letter-spacing: 0.05em;
}

/* Status Badges */
.badge-pending {
    background-color: #64748b;
    color: white;
    padding: 2px 8px;
    border-radius: 4px;
    font-size: 0.75rem;
    font-weight: 600;
}

.badge-running {
    background-color: #3b82f6;
    color: white;
    padding: 2px 8px;
    border-radius: 4px;
    font-size: 0.75rem;
    font-weight: 600;
}

.badge-completed {
    background-color: #10b981;
    color: white;
    padding: 2px 8px;
    border-radius: 4px;
    font-size: 0.75rem;
    font-weight: 600;
}

.badge-failed {
    background-color: #ef4444;
    color: white;
    padding: 2px 8px;
    border-radius: 4px;
    font-size: 0.75rem;
    font-weight: 600;
}

.badge-blocked {
    background-color: #f59e0b;
    color: white;
    padding: 2px 8px;
    border-radius: 4px;
    font-size: 0.75rem;
    font-weight: 600;
}

/* Task Card */
.task-card {
    background-color: #ffffff;
    border: 1px solid #e2e8f0;
    border-radius: 8px;
    padding: 1rem;
    margin-bottom: 0.75rem;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

/* Sidebar Customization */
[data-testid="stSidebar"] {
    background-color: #f8fafc !important;
    border-right: 1px solid #e2e8f0 !important;
}

/* Sidebar Headings and Labels */
[data-testid="stSidebar"] h1,
[data-testid="stSidebar"] h2,
[data-testid="stSidebar"] h3,
[data-testid="stSidebar"] h4 {
    color: #0f172a !important;
    font-weight: 700 !important;
}

[data-testid="stSidebar"] p,
[data-testid="stSidebar"] span,
[data-testid="stSidebar"] label {
    color: #1e293b !important;
}

/* Sidebar Expander Customization - High Contrast Differentiation */
[data-testid="stSidebar"] [data-testid="stExpander"],
[data-testid="stSidebar"] details {
    background-color: #ffffff !important;
    border: 1px solid #cbd5e1 !important;
    border-radius: 8px !important;
    margin-top: 0.5rem !important;
    margin-bottom: 0.75rem !important;
    overflow: hidden !important;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.06) !important;
}

/* Expander Header/Summary - High Contrast Dark Slate with Crisp White Text */
[data-testid="stSidebar"] [data-testid="stExpander"] summary,
[data-testid="stSidebar"] details summary {
    background-color: #1e293b !important;
    color: #ffffff !important;
    font-weight: 600 !important;
    padding: 0.6rem 0.85rem !important;
    border-radius: 6px !important;
    cursor: pointer !important;
    transition: background-color 0.15s ease-in-out;
}

[data-testid="stSidebar"] [data-testid="stExpander"] summary:hover,
[data-testid="stSidebar"] details summary:hover {
    background-color: #0f172a !important;
    color: #ffffff !important;
}

/* Expander Header Text & SVG Chevron */
[data-testid="stSidebar"] [data-testid="stExpander"] summary p,
[data-testid="stSidebar"] [data-testid="stExpander"] summary span,
[data-testid="stSidebar"] details summary p,
[data-testid="stSidebar"] details summary span {
    color: #ffffff !important;
    font-weight: 600 !important;
}

[data-testid="stSidebar"] [data-testid="stExpander"] summary svg,
[data-testid="stSidebar"] details summary svg {
    color: #38bdf8 !important;
    fill: #38bdf8 !important;
}

/* Expander Content Details - Crisp White Background with Deep Dark Text */
[data-testid="stSidebar"] [data-testid="stExpander"] [data-testid="stExpanderDetails"],
[data-testid="stSidebar"] details > div,
[data-testid="stSidebar"] [data-testid="stExpander"] div[role="region"] {
    background-color: #ffffff !important;
    color: #0f172a !important;
    padding: 0.85rem 1rem !important;
    border-top: 1px solid #e2e8f0 !important;
}

[data-testid="stSidebar"] [data-testid="stExpander"] [data-testid="stExpanderDetails"] *,
[data-testid="stSidebar"] details > div *,
[data-testid="stSidebar"] [data-testid="stExpander"] div[role="region"] * {
    color: #1e293b !important;
    background-color: transparent;
}

[data-testid="stSidebar"] [data-testid="stExpander"] [data-testid="stExpanderDetails"] strong,
[data-testid="stSidebar"] [data-testid="stExpander"] [data-testid="stExpanderDetails"] b,
[data-testid="stSidebar"] details > div strong,
[data-testid="stSidebar"] details > div b {
    color: #020617 !important;
    font-weight: 700 !important;
}

[data-testid="stSidebar"] [data-testid="stExpander"] [data-testid="stExpanderDetails"] li,
[data-testid="stSidebar"] details > div li {
    color: #334155 !important;
    margin-bottom: 0.35rem !important;
    line-height: 1.4 !important;
}

[data-testid="stSidebar"] [data-testid="stExpander"] [data-testid="stExpanderDetails"] code,
[data-testid="stSidebar"] details > div code {
    background-color: #f1f5f9 !important;
    color: #0369a1 !important;
    padding: 0.15rem 0.4rem !important;
    border-radius: 4px !important;
    border: 1px solid #e2e8f0 !important;
    font-size: 0.85em !important;
}

/* Global Expander High-Contrast Safeguard */
[data-testid="stExpander"] {
    border: 1px solid #e2e8f0 !important;
    border-radius: 8px !important;
}

[data-testid="stExpander"] summary {
    font-weight: 600 !important;
}

/* Chat Message Styling */
[data-testid="stChatMessage"] {
    border-radius: 10px;
    margin-bottom: 0.5rem;
}

/* Subsystem Metrics Card */
.metric-box {
    background-color: #f1f5f9;
    border-radius: 8px;
    padding: 0.75rem;
    margin-bottom: 0.5rem;
    border-left: 4px solid #3b82f6;
}

.metric-box h4 {
    margin: 0;
    font-size: 0.85rem;
    color: #475569;
}

.metric-box p {
    margin: 0.2rem 0 0 0;
    font-size: 1.1rem;
    font-weight: 700;
    color: #0f172a;
}
</style>
"""
