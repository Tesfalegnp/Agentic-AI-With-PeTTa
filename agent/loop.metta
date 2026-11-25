;; =============================================================================
;; STAGE C - MILESTONE 9: Cognitive Agent Reasoning Loop (Competition Edition)
;; Module: agent/loop.metta
;;
;; FIX: Per-turn context budget enforcement (not just at start).
;; FIX: ask_user now records pending goal and suspends task (true pause/resume).
;; FIX: Original goal preserved throughout all turns.
;; FIX: Completion truthfulness (turn limit vs success vs error are distinct).
;; FIX: Approval-required returns readable observation, not crash.
;; FIX: state-get-context now includes ALL message types.
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "prompt.metta")
!(import! &self "response_parser.metta")
!(import! &self "action_validator.metta")
!(import! &self "state.metta")
!(import! &self "tool_dispatcher.metta")
!(import! &self "tool_result.metta")
!(import! &self "skill_executor.metta")
!(import! &self "skill_result.metta")
!(import! &self "memory_core.metta")
!(import! &self "goal_planner.metta")
!(import! &self "telemetry.metta")
!(import! &self "../python_bridge/bridge.py")

;; =============================================================================
;; Core Recursive Cognitive Step
;; =============================================================================

;; Single reasoning turn. Calls LLM, parses response, dispatches action.
;; Per-turn context budgeting is applied every call via build-agent-prompt.
(= (cognitive-step $provider $original_goal $iteration $max_iterations)
   (if (> $iteration $max_iterations)
       (let $_comp (state-record-completion-status "turn_limit"
                      (string_concat "Turn limit of " (string_concat (repr $max_iterations)
                        " reached. The original goal was: " $original_goal)))
         (AgentResult max_iterations_exceeded
           (string_concat "Task incomplete: Maximum reasoning turns (" (string_concat (repr $max_iterations)
             ") reached. The original goal was preserved throughout but could not be completed within the turn budget."))))
       (let* (($_ev_step (emit-telemetry "cognitive_step" "reasoning"
                            (string_concat "Turn " (repr $iteration) " of " (repr $max_iterations)) ""))
              ;; Build fresh prompt every turn — context budget enforced per turn
              ($ctx     (state-get-context))
              ($prompt  (build-agent-prompt-with-goal $ctx $original_goal))
              ($_ev_llm  (emit-telemetry "llm_query" "llm"
                            (string_concat "Querying " $provider " (Turn " (repr $iteration) ")") ""))
              ($raw_json (py-call (bridge.query $provider $prompt)))
              ($success  (py-call (bridge.get_field $raw_json "success")))
              ($raw_text (py-call (bridge.get_field $raw_json "content")))
              ($error    (py-call (bridge.get_field $raw_json "error"))))
         (if (== $success false)
             (progn
               (emit-telemetry "llm_error" "error" "LLM provider invocation failed" (repr $error))
               (state-add-failure (string_concat "LLM error: " (repr $error)))
               (AgentResult error (string_concat "LLM provider invocation failed: " (repr $error))))
             (let $action_eval (parse-and-validate-response $raw_text)
               (case $action_eval

                 ;; ---- Terminal Actions ----------------------------------------

                 (((ActionValid answer $ans)
                   (progn
                     (emit-telemetry "action_parsed" "action" "Action: answer" $ans)
                     (state-add-assistant-message $ans)
                     (state-record-completion-status "completed" $ans)
                     (AgentResult answer $ans)))

                  ((ActionValid finish $summary)
                   (progn
                     (emit-telemetry "action_parsed" "action" "Action: finish" $summary)
                     (state-add-assistant-message $summary)
                     (state-record-completion-status "completed" $summary)
                     (AgentResult finish $summary)))

                  ((ActionValid error $diag)
                   (progn
                     (emit-telemetry "action_parsed" "action" "Action: error" $diag)
                     (state-add-failure $diag)
                     (state-record-completion-status "failed" $diag)
                     (AgentResult error $diag)))

                  ;; ---- ask_user: TRUE pause/resume --------------------------------
                  ;; Records the pending goal and plan in state, then suspends.
                  ;; The controller handles resumption with the user's answer.
                  ((ActionValid ask_user $question)
                   (progn
                     (emit-telemetry "action_parsed" "action" "Action: ask_user (suspending task)" $question)
                     (state-add-assistant-message (string_concat "[CLARIFICATION NEEDED] " $question))
                     (state-mark-awaiting-clarification $question $original_goal "pending")
                     (state-record-completion-status "blocked" $question)
                     (AgentResult ask_user $question)))

                  ;; ---- Tool Dispatch -------------------------------------------
                  ((ActionValid use_tool $tool $args)
                   (progn
                     (emit-telemetry "tool_dispatching" "tool"
                       (string_concat "Dispatching tool: " (repr $tool)) (repr $args))
                     (let* (($tool_res  (dispatch-tool $tool $args))
                            ($obs_str   (format-tool-observation $tool_res))
                            ($_ev_tool  (emit-telemetry "tool_completed" "tool"
                                          (string_concat "Tool result: " (repr $tool)) $obs_str))
                            ($_log_act  (state-add-assistant-message
                                          (string_concat "Action: use_tool "
                                            (string_concat (repr $tool) (string_concat " " (repr $args))))))
                            ($_log_obs  (state-add-observation $obs_str)))
                       (if (< $iteration $max_iterations)
                           ;; Continue: rebuild prompt with updated context (per-turn budget)
                           (cognitive-step $provider $original_goal (+ $iteration 1) $max_iterations)
                           (let $_comp (state-record-completion-status "turn_limit"
                                          "Turn limit reached after tool execution.")
                             (AgentResult max_iterations_exceeded
                               "Maximum turns reached after tool execution. Last observation attached to context."))))))

                  ;; ---- Skill Dispatch ------------------------------------------
                  ((ActionValid use_skill $skill $args)
                   (progn
                     (emit-telemetry "skill_dispatching" "skill"
                       (string_concat "Executing skill: " (repr $skill)) (repr $args))
                     (let* (($skill_res (execute-skill $skill $args))
                            ($obs_str   (format-skill-observation $skill_res))
                            ($_ev_sk    (emit-telemetry "skill_completed" "skill"
                                          (string_concat "Skill result: " (repr $skill)) $obs_str))
                            ($_log_act  (state-add-assistant-message
                                          (string_concat "Action: use_skill "
                                            (string_concat (repr $skill) (string_concat " " (repr $args))))))
                            ($_log_obs  (state-add-observation $obs_str)))
                       (if (< $iteration $max_iterations)
                           (cognitive-step $provider $original_goal (+ $iteration 1) $max_iterations)
                           (let $_comp (state-record-completion-status "turn_limit"
                                          "Turn limit reached after skill execution.")
                             (AgentResult max_iterations_exceeded
                               "Maximum turns reached after skill execution."))))))

                  ;; ---- Memory Actions ------------------------------------------
                  ((ActionValid remember $category $mem_text)
                   (progn
                     (emit-telemetry "memory_store" "memory"
                       (string_concat "Storing memory: " (repr $category)) "")
                     (let* (($mem_res  (memory-store $category $mem_text))
                            ($obs_str  (format-memory-observation $mem_res))
                            ($_ev_mem  (emit-telemetry "memory_completed" "memory" "Memory stored" $obs_str))
                            ($_log_act (state-add-assistant-message
                                          (string_concat "Action: remember " (repr $category))))
                            ($_log_obs (state-add-observation $obs_str)))
                       (if (< $iteration $max_iterations)
                           (cognitive-step $provider $original_goal (+ $iteration 1) $max_iterations)
                           (let $_comp (state-record-completion-status "turn_limit"
                                          "Turn limit reached after remember action.")
                             (AgentResult max_iterations_exceeded
                               "Maximum turns reached after remember action."))))))

                  ((ActionValid recall $category $query)
                   (progn
                     (emit-telemetry "memory_recall" "memory"
                       (string_concat "Recalling: " (repr $category)) $query)
                     (let* (($mem_res  (memory-recall-query $category $query))
                            ($obs_str  (format-memory-observation $mem_res))
                            ($_ev_rec  (emit-telemetry "memory_completed" "memory" "Memory retrieved" $obs_str))
                            ($_log_act (state-add-assistant-message
                                          (string_concat "Action: recall " (repr $category))))
                            ($_log_obs (state-add-observation $obs_str)))
                       (if (< $iteration $max_iterations)
                           (cognitive-step $provider $original_goal (+ $iteration 1) $max_iterations)
                           (let $_comp (state-record-completion-status "turn_limit"
                                          "Turn limit reached after recall action.")
                             (AgentResult max_iterations_exceeded
                               "Maximum turns reached after recall action."))))))

                  ;; ---- Unknown / Unsupported Action ----------------------------
                  ((ActionUnsupported $kind $target $reason)
                   (progn
                     (emit-telemetry "action_unsupported" "error"
                       (string_concat (repr $target) ": " $reason) "")
                     (let* (($err_obs   (string_concat "ERROR: Unknown or unsupported action '"
                                          (string_concat (repr $target) (string_concat "'. " $reason))))
                            ($_log_obs  (state-add-failure $err_obs)))
                       (if (< $iteration $max_iterations)
                           ;; Return error observation and retry — agent can recover
                           (let* (($_log_obs2 (state-add-observation $err_obs)))
                             (cognitive-step $provider $original_goal (+ $iteration 1) $max_iterations))
                           (AgentResult unsupported $kind
                             (string_concat "Unknown tool/action after turn limit: " $reason))))))

                  ;; ---- Malformed Action — issue correction prompt --------------
                  ((ActionError $err)
                   (if (< $iteration $max_iterations)
                       (progn
                         (emit-telemetry "action_retry" "action"
                           "Malformed action — issuing correction prompt" (repr $err))
                         (state-add-failure (string_concat "Malformed action: " (repr $err)))
                         ;; The state-get-context in the next call will include the failure record
                         (cognitive-step $provider $original_goal (+ $iteration 1) $max_iterations))
                       (AgentResult error
                         (string_concat "Repeated malformed actions. Last error: " (repr $err))))))))))))

;; =============================================================================
;; High-Level Cognitive Cycle Entry Point
;; =============================================================================

(= (run-cognitive-cycle $provider $query $max_iterations)
   (let* (($_ev_rcv (emit-telemetry "query_received" "init" "Query received" $query))
          ($_u      (state-add-user-message $query)))
     (if (== (should-plan-request $query) true)
         (progn
           (emit-telemetry "planning_check" "planning" "Multi-step DAG planning required" $query)
           (let $plan_res (plan-and-execute-request $provider $query)
             (case $plan_res
               (((AgentResult finish $fin)
                 (let $_a (state-add-assistant-message $fin)
                   (AgentResult finish $fin)))
                ((AgentResult answer $ans)
                 (let $_a (state-add-assistant-message $ans)
                   (AgentResult answer $ans)))
                ($other $other)))))
         (let* (($_ev_pl (emit-telemetry "planning_check" "reasoning"
                            "Single-step cognitive loop" $query)))
           ;; Pass original goal through all turns for preservation
           (cognitive-step $provider $query 1 $max_iterations)))))

;; =============================================================================
;; Resume After Clarification
;; =============================================================================

;; Resume a suspended task after the user provided clarification.
;; Appends the user's answer, clears clarification state, and re-runs.
(= (resume-after-clarification $provider $user_answer $max_iterations)
   (let* (($pending_goal (state-get-pending-goal))
          ($_ev_res      (emit-telemetry "clarification_resumed" "action"
                            "Resuming task with user clarification" $user_answer))
          ($_ans_obs     (state-add-observation
                            (string_concat "[User Clarification] " $user_answer)))
          ($_clr         (state-clear-clarification)))
     (if (== $pending_goal "")
         ;; No pending goal — treat as new query
         (run-cognitive-cycle $provider $user_answer $max_iterations)
         ;; Resume the suspended goal with clarification injected
         (let* (($combined_goal (string_concat $pending_goal
                                   (string_concat " [User provided clarification: " (string_concat $user_answer "]")))))
           (cognitive-step $provider $combined_goal 1 $max_iterations)))))
