# PeTTa Agentic AI Framework: Setup & Configuration Guide

This document provides complete, reproducible instructions for installing, configuring, running, and troubleshooting the **PeTTa Agentic AI Framework** on Ubuntu Linux.

---

## 1. Prerequisites & System Requirements

| Requirement | Supported Version | Notes |
| :--- | :--- | :--- |
| **Operating System** | Ubuntu 22.04 LTS / 24.04 LTS (x86_64) | Tested natively on Ubuntu Linux |
| **SWI-Prolog** | 9.2.0 or newer | Must include `janus`, `json`, `pcre` packages |
| **PeTTa Runtime** | Latest commit | Built and installed to `/home/hope/.local/bin/petta` |
| **Python** | Python 3.10, 3.11, 3.12, 3.13, 3.14 | Managed via Python virtual environment (`.venv`) |
| **LLM Access** | Gemini, OpenAI, or DeepSeek API key | Configured via `.env` |

---

## 2. Installation Step-by-Step

### 2.1. Clone the Repository
```bash
git clone https://github.com/Tesfalegnp/Agentic-AI-With-PeTTa.git
cd Agentic-AI-With-PeTTa
```

### 2.2. Set Up Python Virtual Environment
Always run the framework within a dedicated Python virtual environment to avoid conflicts:

```bash
# Create virtual environment
python3 -m venv .venv

# Activate virtual environment
source .venv/bin/activate

# Upgrade pip and install dependencies
pip install --upgrade pip
pip install -r requirements.txt
```

### 2.3. Verify PeTTa Executable
Ensure the `petta` binary is in your `PATH` or available at `/home/hope/.local/bin/petta`:

```bash
# Verify petta installation
which petta || echo "petta located at /home/hope/.local/bin/petta"
```

If `petta` is installed in a custom location, specify it via the environment variable:
```bash
export PETTA_BIN=/path/to/your/petta
```

---

## 3. Environment & LLM Provider Configuration

The framework uses a clean `.env` file for configuration. Copy the provided `.env.example` template:

```bash
cp .env.example .env
```

Open `.env` in your editor and configure your preferred provider and API credentials:

```bash
# =============================================================================
# PeTTa Agentic AI Framework Configuration
# =============================================================================

# Active LLM Provider: 'gemini', 'openai', 'deepseek', or 'generic'
LLM_PROVIDER=gemini

# -----------------------------------------------------------------------------
# Google Gemini Configuration (Default)
# -----------------------------------------------------------------------------
GEMINI_API_KEY=your_gemini_api_key_here
GEMINI_MODEL=gemini-2.5-flash

# -----------------------------------------------------------------------------
# OpenAI Configuration
# -----------------------------------------------------------------------------
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_MODEL=gpt-4o-mini
OPENAI_BASE_URL=https://api.openai.com/v1

# -----------------------------------------------------------------------------
# DeepSeek Configuration
# -----------------------------------------------------------------------------
DEEPSEEK_API_KEY=your_deepseek_api_key_here
DEEPSEEK_MODEL=deepseek-chat
DEEPSEEK_BASE_URL=https://api.deepseek.com/v1

# -----------------------------------------------------------------------------
# Generic OpenAI-Compatible Configuration (Ollama / vLLM / LocalAI)
# -----------------------------------------------------------------------------
GENERIC_OPENAI_API_KEY=optional_or_placeholder
GENERIC_OPENAI_MODEL=llama3.1
GENERIC_OPENAI_BASE_URL=http://localhost:11434/v1
```

> [!IMPORTANT]
> Never commit your real `.env` file to version control. It is strictly excluded by `.gitignore`. Keep `.env.example` up to date with placeholders only.

---

## 4. Launching the Application

### Option A: Interactive Streamlit Web Interface (Recommended)
The web interface provides real-time streaming progress, visual task DAG execution, memory inspection, and evaluator demonstration modes:

```bash
# Ensure virtual environment is active
source .venv/bin/activate

# Launch Web UI
streamlit run ui/app.py
```

The application will launch and open in your default browser at:
`http://localhost:8501`

To specify a custom port or run headlessly:
```bash
streamlit run ui/app.py --server.port 8501 --server.headless true
```

### Option B: Interactive Terminal CLI Loop
For headless environments or direct terminal interaction:

```bash
# Launch terminal conversational agent
petta main.metta
```

To exit the terminal loop, type `exit`, `quit`, or `bye`. Stored memories and learned adaptations will be persisted safely to disk on exit.

---

## 5. Verification & Health Check

Run the comprehensive automated test suite to verify your setup:

```bash
# 1. Run all Python unit and integration tests
.venv/bin/python3 -m unittest discover tests/

# 2. Run PeTTa subsystem regression tests (54 tests)
.venv/bin/python3 -c "
import subprocess, glob
for d in ['tests/protocol', 'tests/agent', 'tests/tools', 'tests/skills', 'tests/memory', 'tests/planning', 'tests/adaptation']:
    for f in sorted(glob.glob(f'{d}/*.metta')):
        res = subprocess.run(['/home/hope/.local/bin/petta', f], capture_output=True, text=True)
        assert res.returncode == 0, f'Failed: {f}'
print('All 54 PeTTa subsystem tests passed!')
"
```

---

## 6. Troubleshooting Common Issues

### 1. `GEMINI_API_KEY not found in environment`
- Ensure `.env` is located in the project root directory.
- Verify `python-dotenv` is installed (`pip install python-dotenv`).
- Confirm the variable name matches exactly `GEMINI_API_KEY` (or the respective provider's key).

### 2. PeTTa Subprocess Deadlock / Stalling
- PeTTa compiler output can exceed standard 64 KB Linux pipe buffers. The client adapter (`ui/agent_client.py`) automatically redirects compiler output to `memory/gateway_stdout.log`. Do not modify `execute_query_stream()` to use raw `stdout=subprocess.PIPE` without draining.

### 3. Missing `lib_import` or Prolog Modules
- Ensure SWI-Prolog packages are installed:
  ```bash
  sudo apt-get install swi-prolog swi-prolog-nox
  ```
- Verify `/home/hope/Projects/PeTTa` contains the required libraries (`lib_import.pl`, `metta_interp.pl`).
