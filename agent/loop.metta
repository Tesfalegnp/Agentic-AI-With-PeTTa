;; =============================================================================
;; STAGE C - MILESTONE 9: Cognitive Agent Reasoning Loop with Tools, Skills & Memory
;; Module: agent/loop.metta
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

;; Recursive single reasoning step
(= (cognitive-step $provider $prompt $iteration $max_iterations)
   (if (> $iteration $max_iterations)
       (AgentResult max_iterations_exceeded "Reasoning iteration limit reached.")
       (let* (($_ev_step (emit-telemetry "cognitive_step" "reasoning" (string_concat "Reasoning iteration " (repr $iteration)) ""))
              ($_ev_llm  (emit-telemetry "llm_query" "llm" (string_concat "Querying " (string_concat $provider " provider via bridge")) ""))
              ($raw_json (py-call (bridge.query $provider $prompt)))
              ($success  (py-call (bridge.get_field $raw_json "success")))
              ($raw_text (py-call (bridge.get_field $raw_json "content")))
              ($error    (py-call (bridge.get_field $raw_json "error"))))
         (if (== $success false)
             (progn
               (emit-telemetry "llm_error" "error" "LLM provider invocation failed" (repr $error))
               (AgentResult error (string_concat "LLM provider invocation failed: " (repr $error))))
             (let $action_eval (parse-and-validate-response $raw_text)
               (case $action_eval
                 (((ActionValid answer $ans)
                   (progn
                     (emit-telemetry "action_parsed" "action" "Action parsed: answer" $ans)
                     (AgentResult answer $ans)))

                  ((ActionValid ask_user $question)
                   (progn
                     (emit-telemetry "action_parsed" "action" "Action parsed: ask_user" $question)
                     (AgentResult ask_user $question)))

                  ((ActionValid finish $summary)
                   (progn
                     (emit-telemetry "action_parsed" "action" "Action parsed: finish" $summary)
                     (AgentResult finish $summary)))

                  ((ActionValid error $diag)
                   (progn
                     (emit-telemetry "action_parsed" "action" "Action parsed: error" $diag)
                     (AgentResult error $diag)))

                  ((ActionValid use_tool $tool $args)
                   (progn
                     (emit-telemetry "tool_dispatching" "tool" (string_concat "Dispatching tool: " (repr $tool)) (repr $args))
                     (let* (($tool_res   (dispatch-tool $tool $args))
                            ($obs_str    (format-tool-observation $tool_res))
                            ($_ev_tool   (emit-telemetry "tool_completed" "tool" (string_concat "Observation from tool: " (repr $tool)) $obs_str))
                            ($_log_call  (state-add-assistant-message (string_concat "Action: use_tool " (string_concat (repr $tool) (string_concat " " (repr $args))))))
                            ($_log_obs   (state-add-observation $obs_str)))
                       (if (< $iteration $max_iterations)
                           (let $continue_prompt (string_concat $prompt (string_concat "\n" (string_concat $obs_str "\nResponse: ")))
                             (cognitive-step $provider $continue_prompt (+ $iteration 1) $max_iterations))
                           (AgentResult max_iterations_exceeded "Reasoning iteration limit reached after tool execution.")))))

                  ((ActionValid use_skill $skill $args)
                   (progn
                     (emit-telemetry "skill_dispatching" "skill" (string_concat "Executing skill workflow: " (repr $skill)) (repr $args))
                     (let* (($skill_res  (execute-skill $skill $args))
                            ($obs_str    (format-skill-observation $skill_res))
                            ($_ev_skill  (emit-telemetry "skill_completed" "skill" (string_concat "Observation from skill: " (repr $skill)) $obs_str))
                            ($_log_call  (state-add-assistant-message (string_concat "Action: use_skill " (string_concat (repr $skill) (string_concat " " (repr $args))))))
                            ($_log_obs   (state-add-observation $obs_str)))
                       (if (< $iteration $max_iterations)
                           (let $continue_prompt (string_concat $prompt (string_concat "\n" (string_concat $obs_str "\nResponse: ")))
                             (cognitive-step $provider $continue_prompt (+ $iteration 1) $max_iterations))
                           (AgentResult max_iterations_exceeded "Reasoning iteration limit reached after skill execution.")))))

                  ((ActionValid remember $category $mem_text)
                   (progn
                     (emit-telemetry "memory_store" "memory" (string_concat "Storing memory in " (repr $category)) $mem_text)
                     (let* (($mem_res    (memory-store $category $mem_text))
                            ($obs_str    (format-memory-observation $mem_res))
                            ($_ev_mem    (emit-telemetry "memory_completed" "memory" "Memory record stored" $obs_str))
                            ($_log_call  (state-add-assistant-message (string_concat "Action: remember " (string_concat (repr $category) (string_concat " " (repr $mem_text))))))
                            ($_log_obs   (state-add-observation $obs_str)))
                       (if (< $iteration $max_iterations)
                           (let $continue_prompt (string_concat $prompt (string_concat "\n" (string_concat $obs_str "\nResponse: ")))
                             (cognitive-step $provider $continue_prompt (+ $iteration 1) $max_iterations))
                           (AgentResult max_iterations_exceeded "Reasoning iteration limit reached after remember action.")))))

                  ((ActionValid recall $category $query)
                   (progn
                     (emit-telemetry "memory_recall" "memory" (string_concat "Recalling context for " (repr $category)) $query)
                     (let* (($mem_res    (memory-recall-query $category $query))
                            ($obs_str    (format-memory-observation $mem_res))
                            ($_ev_rec    (emit-telemetry "memory_completed" "memory" "Memory context retrieved" $obs_str))
                            ($_log_call  (state-add-assistant-message (string_concat "Action: recall " (string_concat (repr $category) (string_concat " " (repr $query))))))
                            ($_log_obs   (state-add-observation $obs_str)))
                       (if (< $iteration $max_iterations)
                           (let $continue_prompt (string_concat $prompt (string_concat "\n" (string_concat $obs_str "\nResponse: ")))
                             (cognitive-step $provider $continue_prompt (+ $iteration 1) $max_iterations))
                           (AgentResult max_iterations_exceeded "Reasoning iteration limit reached after recall action.")))))

                  ((ActionUnsupported $kind $target $reason)
                   (progn
                     (emit-telemetry "action_unsupported" "error" (string_concat (repr $target) (string_concat ": " $reason)) "")
                     (AgentResult unsupported $kind (string_concat (repr $target) (string_concat ": " $reason)))))

                  ((ActionError $err)
                   (if (< $iteration $max_iterations)
                       (progn
                         (emit-telemetry "action_retry" "action" "Action malformed, issuing correction prompt to LLM" (repr $err))
                         (let $retry_prompt (string_concat $prompt "\n[CORRECTION: Your previous output was malformed. Respond ONLY with a valid canonical action.]")
                           (cognitive-step $provider $retry_prompt (+ $iteration 1) $max_iterations)))
                       (AgentResult error (string_concat "Action validation failed: " (repr $err))))))))))))

;; High-level cognitive cycle for one user request
(= (run-cognitive-cycle $provider $query $max_iterations)
   (let* (($context (state-get-context))
          ($_ev_rcv (emit-telemetry "query_received" "init" "Evaluating reasoning path" $query))
          ($_u      (state-add-user-message $query)))
     (if (== (should-plan-request $query) true)
         (progn
           (emit-telemetry "planning_check" "planning" "Multi-step goal decomposition required" $query)
           (let $plan_res (plan-and-execute-request $provider $query)
             (case $plan_res
               (((AgentResult finish $fin)
                 (let $_a (state-add-assistant-message $fin)
                   (AgentResult finish $fin)))
                ((AgentResult answer $ans)
                 (let $_a (state-add-assistant-message $ans)
                   (AgentResult answer $ans)))
                ($other $other)))))
         (let* (($_ev_pl  (emit-telemetry "planning_check" "reasoning" "Single-step cognitive loop engaged" $query))
                ($prompt  (build-agent-prompt $context $query))
                ($_ev_pr  (emit-telemetry "prompt_constructed" "context" "Prompt constructed with working memory, tools & skills" ""))
                ($result  (cognitive-step $provider $prompt 1 $max_iterations)))
           (case $result
             (((AgentResult answer $ans)
               (let $_a (state-add-assistant-message $ans)
                 (AgentResult answer $ans)))
              ((AgentResult ask_user $q)
               (let $_a (state-add-assistant-message $q)
                 (AgentResult ask_user $q)))
              ((AgentResult finish $s)
               (let $_a (state-add-assistant-message $s)
                 (AgentResult finish $s)))
              ($other $other)))))))
