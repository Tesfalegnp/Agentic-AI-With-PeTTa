;; =============================================================================
;; STAGE D - MILESTONE 11: Goal-Driven Planning & Execution Coordinator
;; Module: agent/goal_planner.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function atomic_list_concat)
!(import_prolog_function string_concat)
!(import! &self "plan_types.metta")
!(import! &self "goal_manager.metta")
!(import! &self "plan_state.metta")
!(import! &self "plan_history.metta")
!(import! &self "plan_builder.metta")
!(import! &self "plan_validator.metta")
!(import! &self "task_scheduler.metta")
!(import! &self "plan_executor.metta")
!(import! &self "plan_recovery.metta")
!(import! &self "plan_verifier.metta")
!(import! &self "tool_registry.metta")
!(import! &self "skill_registry.metta")
!(import! &self "memory_ranking.metta")
!(import! &self "context_manager.metta")
!(import! &self "telemetry.metta")
!(import! &self "../python_bridge/bridge.py")

;; Deterministic criteria: Should this query be planned?
(= (should-plan-request $query)
   (let $req (is_planning_required $query)
     (case $req
       (((true $reason) true)
        ($_ false)))))

;; Construct the specialized Planning Prompt
(= (build-planning-prompt $query)
   (let* (($tools_desc  (format-tools-for-prompt))
          ($skills_desc (format-skills-for-prompt))
          ($memories    (format-relevant-memories-context $query 3))
          ($mem_sec     (if (== $memories "") "" (string_concat "\n--- RELEVANT CONTEXT ---\n" $memories))))
     (string_concat
"You are the PeTTa Agentic Planner.
The user has submitted a complex multi-step request that requires goal decomposition, tool/skill selection, and dependency scheduling.

User Goal: \"" (string_concat $query (string_concat "\"
" (string_concat $mem_sec (string_concat "
--- AVAILABLE TOOLS ---
" (string_concat $tools_desc (string_concat "
--- AVAILABLE SKILLS ---
" (string_concat $skills_desc "

INSTRUCTIONS:
Decompose the user goal into 2 to 5 ordered tasks.
Respond ONLY with a structured (plan-proposal ...) S-expression without code fences, markdown, or commentary.

Syntax:
(plan-proposal \"<Plan Description>\"
  (
    (task <id> tool <tool_name> (<arg1> ...) (<dep1> ...))
    (task <id> skill <skill_name> (<arg1> ...) (<dep1> ...))
  )
)

Rules:
1. Task IDs must be sequential tokens: t1, t2, t3, etc.
2. Executor must be 'tool' or 'skill'.
3. Use only registered tools: calculator, word_counter, text_analyzer, string_reverser, datetime, read_file, write_file, run_command, send_message.
4. Use only registered skills: math_skill, text_process_skill, research_skill.
5. Task dependencies (<dep1> ...) must refer to prior task IDs in the plan (e.g. () for no dependencies, (t1) to depend on t1).
6. Arguments must be a list of values, NOT key-value pairs. e.g. (\"some text\") or (\"50 * 4\") or ((ref t1)).
7. Output MUST start with (plan-proposal and end with ). No code fences, no other text!

Example Proposal:
(plan-proposal \"Analyze text and compute word count\"
  (
    (task t1 tool word_counter (\"Autonomous Cognitive Architecture\") ())
    (task t2 tool text_analyzer (\"Autonomous Cognitive Architecture\") (t1))
  )
)

Plan Proposal: "))))))))))

;; Format task outputs into a readable summary string
(= (format-task-summary ()) "")
(= (format-task-summary $tasks)
   (let ($task $rest) (decons-atom $tasks)
     (case $task
       (((PlanTask $tid $pid $desc $type $name $args $deps completed (TaskResult success $val))
         (let $line (string_concat "- Task " (string_concat (repr $tid) (string_concat " (" (string_concat (repr $name) (string_concat "): " (string_concat (repr $val) "\n"))))))
           (string_concat $line (format-task-summary $rest))))
        ($_ (format-task-summary $rest))))))

;; -----------------------------------------------------------------------------
;; Modular Plan Execution Pipeline (clean compile to Prolog clauses)
;; -----------------------------------------------------------------------------

(= (plan-format-final-result $goal_id $pid $verif)
   (case $verif
     (((GoalVerified $gid $pid)
       (progn
         (emit-telemetry "goal_verified" "verification" "Goal completion successfully verified" (repr $gid))
         (let* (($tasks (plan-get-tasks $pid))
                ($summary (format-task-summary $tasks))
                ($final_ans (string_concat "Goal achieved through planned multi-step execution:\n" $summary)))
           (AgentResult finish $final_ans))))
      ((GoalIncomplete $gid $reason)
       (progn
         (emit-telemetry "goal_incomplete" "verification" "Goal verification incomplete" $reason)
         (goal-update-status $goal_id failed)
         (AgentResult error (string_concat "Goal verification failed: " $reason)))))))

(= (plan-finish-verification $goal_id $pid $exec_res)
   (case $exec_res
     (((PlanExecutionSuccess $pid)
       (progn
         (emit-telemetry "plan_execution_success" "execution" "All scheduled tasks executed successfully" (repr $pid))
         (let $verif_res (verify-plan-completion $goal_id $pid)
           (plan-format-final-result $goal_id $pid $verif_res))))
      ((PlanExecutionBlocked $pid)
       (progn
         (emit-telemetry "plan_blocked" "execution" "Plan execution blocked due to failed task dependency" (repr $pid))
         (goal-update-status $goal_id blocked)
         (AgentResult error "Plan execution blocked due to failed task dependency.")))
      ((PlanExecutionHalted $pid $reason)
       (progn
         (emit-telemetry "plan_halted" "execution" "Plan execution halted" $reason)
         (goal-update-status $goal_id failed)
         (AgentResult error (string_concat "Plan execution halted: " $reason)))))))

(= (plan-execute-and-verify $goal_id $pid $val_res)
   (case $val_res
     (((PlanValidationSuccess $pid)
       (progn
         (emit-telemetry "plan_validated" "planning" "Plan DAG and syntax validated successfully" (repr $pid))
         (let $exec_res (execute-plan $pid)
           (plan-finish-verification $goal_id $pid $exec_res))))
      ((PlanValidationFailure $pid $v_reason)
       (progn
         (emit-telemetry "plan_validation_failed" "planning" "Plan proposal rejected by validator" $v_reason)
         (goal-update-status $goal_id failed)
         (AgentResult error (string_concat "Plan proposal rejected by validator: " $v_reason)))))))

(= (plan-validate-and-run $goal_id $build_res)
   (case $build_res
     (((PlanBuilt $plan_id)
       (progn
         (emit-telemetry "plan_built" "planning" "Plan structure built from proposal" (repr $plan_id))
         (let $val_res (validate-plan $plan_id)
           (plan-execute-and-verify $goal_id $plan_id $val_res))))
      ((PlanBuildFailed $b_reason)
       (progn
         (emit-telemetry "plan_build_failed" "planning" "Failed to build plan from proposal" $b_reason)
         (goal-update-status $goal_id failed)
         (AgentResult error (string_concat "Plan build failed: " $b_reason)))))))

(= (plan-build-and-run $goal_id $parse_res)
   (case $parse_res
     (((PlanProposalParsed $proposal)
       (progn
         (emit-telemetry "plan_proposal_parsed" "planning" "Plan proposal S-expression parsed successfully" "")
         (let $build_res (build-plan-from-proposal $goal_id $proposal)
           (plan-validate-and-run $goal_id $build_res))))
      ((PlanProposalError $p_err)
       (progn
         (emit-telemetry "plan_proposal_error" "planning" "Invalid plan proposal format" $p_err)
         (goal-update-status $goal_id failed)
         (AgentResult error (string_concat "Invalid plan proposal: " $p_err)))))))

;; Execute complete planning cycle for a complex request
(= (plan-and-execute-request $provider $query)
   (let* (($g_res (goal-create $query))
          ($goal_id (case $g_res (((GoalCreated $gid) $gid))))
          ($_ev_g (emit-telemetry "goal_created" "planning" (string_concat "Goal created: " (repr $goal_id)) $query))
          ($planning_prompt (build-planning-prompt $query))
          ($_ev_pr (emit-telemetry "plan_proposal_request" "planning" "Requesting plan proposal from LLM planner" (repr $goal_id)))
          ($raw_json (py-call (bridge.query $provider $planning_prompt)))
          ($success  (py-call (bridge.get_field $raw_json "success")))
          ($raw_text (py-call (bridge.get_field $raw_json "content")))
          ($error    (py-call (bridge.get_field $raw_json "error"))))
     (if (== $success false)
         (progn
           (emit-telemetry "plan_llm_error" "planning" "LLM planner invocation failed" (repr $error))
           (goal-update-status $goal_id failed)
           (AgentResult error (string_concat "LLM planner query failed: " (repr $error))))
         (let* (($_ev_pp (emit-telemetry "plan_proposal_received" "planning" "Plan proposal received from LLM planner" ""))
                ($parse_res (parse-plan-proposal $raw_text)))
           (plan-build-and-run $goal_id $parse_res)))))
