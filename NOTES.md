# PeTTa Agentic AI Framework — Project Notes & Verification

## Overview
This repository contains the complete, verified **PeTTa Agentic AI Framework**, combining symbolic logic reasoning and knowledge representation in PeTTa (SWI-Prolog + MeTTa) with Large Language Model orchestration.

## Key Project Deliverables
1. **Core Runtime**: PeTTa owns the continuous cognitive loop, prompt generation, action validation, memory retrieval, task decomposition, and plan recovery.
2. **Canonical 8-Action Protocol**: Formally validated S-expression grammar before execution.
3. **10 Built-in Tools with Safety Protection**:
   - Safe File I/O: `read_file`, `write_file`
   - Guarded Shell: `run_command` with timeout and destructive command blocking (`rm -rf`, `mkfs`, etc.) in `tools/system_primitives.pl`
   - Web Search: `web_search` with Tavily, Brave, and DuckDuckGo fallback via `python_bridge/search_bridge.py`
   - System & Math: `send_message`, `ask_user`, `calculator`, `word_counter`, `string_reverser`, `time_now`
4. **Interactive Streamlit Web UI**: Real-time event streaming and 7 pre-populated Evaluator Demonstration scenarios.
5. **Testing & Verification**: 108/108 automated tests passing (68 PeTTa tests + 40 Python tests).

## Consolidated Documentation
- **Architecture & System Design**: [`docs/SYSTEM_ARCHITECTURE.md`](docs/SYSTEM_ARCHITECTURE.md)
- **Evaluator Verification & Test Report**: [`docs/EVALUATION_REPORT.md`](docs/EVALUATION_REPORT.md)
- **Executive Summary Document**: [`docs/Agentic_AI_With_PeTTa_Summary.docx`](docs/Agentic_AI_With_PeTTa_Summary.docx)
- **Submission Evidence Logs**: [`logs/submission/`](logs/submission/)
