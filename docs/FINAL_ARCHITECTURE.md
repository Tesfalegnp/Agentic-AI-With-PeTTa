# Final Architecture Documentation: PeTTa Agentic AI Framework

## 1. System Overview & Purity of Agent Runtime

The **PeTTa Agentic AI Framework** couples symbolic artificial intelligence with neural Large Language Models.

Unlike typical Python-centric agent libraries, this architecture enforces a strict physical boundary:
- **PeTTa Symbolic Core:** Owns the cognitive loop, prompt generation, action grammar validation, tool registration & dispatch, DAG goal planning, memory management, and adaptive learning.
- **Python Transport Layer:** Stateless REST HTTP client invoking Gemini, OpenAI, DeepSeek, or local Ollama endpoints via SWI-Prolog's Janus bridge.
- **Presentation Layer:** Subprocess-isolated Streamlit application tailing unbuffered JSONL telemetry.

```mermaid
flowchart TD
    subgraph UI_CLI ["User Interfaces"]
        CLI["PeTTa Interactive CLI (main.metta)"]
        Streamlit["Streamlit Web App (ui/app.py)"]
    end

    subgraph IPC ["Safe IPC & Gateway"]
        Gateway["UI Gateway (agent/ui_gateway.metta)"]
        Telemetry["Telemetry Engine (telemetry_io.pl)"]
        EventStream[("session_events.jsonl")]
    end

    subgraph PeTTa_Core ["PeTTa Autonomous Symbolic Core"]
        Loop["Cognitive Loop (agent/loop.metta)"]
        ActionVal["Canonical Action Validator (agent/action_validator.metta)"]
        PromptEng["Prompt Engine & Context Budget (agent/prompt.metta)"]
        
        subgraph Planning_Subsystem ["Goal-Driven Planning Engine"]
            GoalMgr["Goal Manager (&goal_space)"]
            Scheduler["DAG Task Scheduler (agent/task_scheduler.metta)"]
            Executor["Plan Executor (agent/plan_executor.metta)"]
            Verifier["Plan Verifier (agent/plan_verifier.metta)"]
        end

        subgraph Tool_Skill_Subsystem ["Tool & Skill Execution Engine"]
            ToolReg["Tool Registry (&tool_registry)"]
            ToolDisp["Tool Dispatcher (agent/tool_dispatcher.metta)"]
            SystemTools["System Primitives (tools/system_primitives.pl)"]
            SkillReg["Skill Registry (&skill_registry)"]
            SkillExec["Skill Executor (agent/skill_executor.metta)"]
        end

        subgraph Memory_Adaptation ["Persistent Memory & Learning"]
            ConvSpace[("&conversation Space")]
            LongTermSpace[("&long_term Space")]
            AdaptSpace[("&adaptation_space")]
            AdaptEngine["Adaptive Learning (agent/adaptation_engine.metta)"]
        end
    end

    subgraph Python_Bridge ["Python Transport Bridge"]
        Bridge["Stateless Bridge (python_bridge/bridge.py)"]
        Providers["Gemini / OpenAI / DeepSeek / Generic REST"]
    end

    CLI --> Loop
    Streamlit --> Gateway
    Gateway --> Telemetry
    Telemetry --> EventStream
    Streamlit -.->|Tails| EventStream

    Gateway --> Loop
    Loop --> ActionVal
    Loop --> PromptEng
    Loop --> Planning_Subsystem
    Loop --> Tool_Skill_Subsystem
    Loop --> Memory_Adaptation
    Loop <==>|Janus py-call| Bridge
    Bridge --> Providers

    ToolDisp --> SystemTools
```

## 2. Mandatory Five Tools & Built-In System Primitives

1. **`read_file`:** Safe UTF-8 file reading with path existence check and 1 MB size bound.
2. **`write_file`:** Safe UTF-8 file writing with critical system path protection (`/etc`, `/usr`, `/bin`).
3. **`run_command`:** Bash shell execution via SWI-Prolog `process_create/3` with configurable timeout and destructive command blocking (`rm -rf`, `mkfs`, `dd`, `shutdown`) requiring `Approved=true`.
4. **`send_message`:** Direct status messaging to user.
5. **`ask_user`:** Canonical clarification action for interactive turn resolution.
6. **Additional Built-in Tools:** `calculator`, `word_counter`, `text_analyzer`, `string_reverser`, `datetime`.
