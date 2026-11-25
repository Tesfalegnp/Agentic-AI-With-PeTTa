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
[data-testid="stSidebar"],
section[data-testid="stSidebar"],
div[data-testid="stSidebarUserContent"] {
    background-color: #0f172a !important;
    color: #f8fafc !important;
    border-right: 1px solid #334155 !important;
}

/* Sidebar Headings and Labels */
[data-testid="stSidebar"] h1,
[data-testid="stSidebar"] h2,
[data-testid="stSidebar"] h3,
[data-testid="stSidebar"] h4 {
    color: #38bdf8 !important;
    font-weight: 700 !important;
}

[data-testid="stSidebar"] p,
[data-testid="stSidebar"] span,
[data-testid="stSidebar"] label {
    color: #e2e8f0 !important;
}

/* Sidebar Expander Customization - High Contrast Differentiation */
[data-testid="stSidebar"] [data-testid="stExpander"],
[data-testid="stSidebar"] details {
    background-color: #1e293b !important;
    border: 1px solid #475569 !important;
    border-radius: 8px !important;
    margin-top: 0.5rem !important;
    margin-bottom: 0.75rem !important;
    overflow: hidden !important;
    box-shadow: 0 2px 6px rgba(0, 0, 0, 0.25) !important;
}

/* Expander Header/Summary - High Contrast Slate with Vibrant Cyan Text */
[data-testid="stSidebar"] [data-testid="stExpander"] summary,
[data-testid="stSidebar"] details summary {
    background-color: #334155 !important;
    color: #ffffff !important;
    font-weight: 600 !important;
    padding: 0.65rem 0.9rem !important;
    border-radius: 6px !important;
    cursor: pointer !important;
    transition: background-color 0.15s ease-in-out;
}

[data-testid="stSidebar"] [data-testid="stExpander"] summary:hover,
[data-testid="stSidebar"] details summary:hover {
    background-color: #475569 !important;
    color: #38bdf8 !important;
}

/* Expander Header Text & SVG Chevron */
[data-testid="stSidebar"] [data-testid="stExpander"] summary p,
[data-testid="stSidebar"] [data-testid="stExpander"] summary span,
[data-testid="stSidebar"] details summary p,
[data-testid="stSidebar"] details summary span {
    color: #f8fafc !important;
    font-weight: 600 !important;
}

[data-testid="stSidebar"] [data-testid="stExpander"] summary svg,
[data-testid="stSidebar"] details summary svg {
    color: #38bdf8 !important;
    fill: #38bdf8 !important;
}

/* Expander Content Details - Deep Dark Surface with Crisp Light Text */
[data-testid="stSidebar"] [data-testid="stExpander"] [data-testid="stExpanderDetails"],
[data-testid="stSidebar"] details > div,
[data-testid="stSidebar"] [data-testid="stExpander"] div[role="region"] {
    background-color: #1e293b !important;
    color: #f1f5f9 !important;
    padding: 0.85rem 1rem !important;
    border-top: 1px solid #334155 !important;
}

[data-testid="stSidebar"] [data-testid="stExpander"] [data-testid="stExpanderDetails"] *,
[data-testid="stSidebar"] details > div *,
[data-testid="stSidebar"] [data-testid="stExpander"] div[role="region"] * {
    color: #e2e8f0 !important;
    background-color: transparent;
}

[data-testid="stSidebar"] [data-testid="stExpander"] [data-testid="stExpanderDetails"] strong,
[data-testid="stSidebar"] [data-testid="stExpander"] [data-testid="stExpanderDetails"] b,
[data-testid="stSidebar"] details > div strong,
[data-testid="stSidebar"] details > div b {
    color: #38bdf8 !important;
    font-weight: 700 !important;
}

[data-testid="stSidebar"] [data-testid="stExpander"] [data-testid="stExpanderDetails"] li,
[data-testid="stSidebar"] details > div li {
    color: #cbd5e1 !important;
    margin-bottom: 0.35rem !important;
    line-height: 1.4 !important;
}

[data-testid="stSidebar"] [data-testid="stExpander"] [data-testid="stExpanderDetails"] code,
[data-testid="stSidebar"] details > div code {
    background-color: #0f172a !important;
    color: #7dd3fc !important;
    padding: 0.2rem 0.45rem !important;
    border-radius: 4px !important;
    border: 1px solid #334155 !important;
    font-size: 0.88em !important;
}

/* Subsystem Metrics Card */
.metric-box {
    background-color: #1e293b;
    border-radius: 8px;
    padding: 0.75rem;
    margin-bottom: 0.5rem;
    border: 1px solid #334155;
    border-left: 4px solid #38bdf8;
}

.metric-box h4 {
    margin: 0;
    font-size: 0.85rem;
    color: #94a3b8 !important;
}

.metric-box p {
    margin: 0.2rem 0 0 0;
    font-size: 1.1rem;
    font-weight: 700;
    color: #f8fafc !important;
}
</style>
"""
