;; =============================================================================
;; STAGE D - MILESTONE 13: Web UI Gateway Entry Point
;; Module: agent/ui_gateway.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "telemetry.metta")
!(import! &self "loop.metta")
!(import! &self "memory_core.metta")
!(import! &self "adaptation_persistence.metta")
!(import! &self "plan_state.metta")

;; Dispatch and record final gateway result using case matching
(= (process-gateway-result $res)
   (case $res
     (((AgentResult answer $ans)
       (progn
         (emit-telemetry "response_final" "complete" "Generated final direct answer" $ans)
         (write-gateway-result "success" "answer" $ans)
         (println! (string_concat "Gateway Result: Answer - " $ans))))

      ((AgentResult finish $summary)
       (progn
         (emit-telemetry "response_final" "complete" "Goal achieved and execution finished" $summary)
         (write-gateway-result "success" "finish" $summary)
         (println! (string_concat "Gateway Result: Finish - " $summary))))

      ((AgentResult ask_user $question)
       (progn
         (emit-telemetry "response_final" "complete" "Requesting clarification from user" $question)
         (write-gateway-result "success" "ask_user" $question)
         (println! (string_concat "Gateway Result: AskUser - " $question))))

      ((AgentResult error $err)
       (progn
         (emit-telemetry "response_error" "error" (string_concat "Agent execution error: " (repr $err)) (repr $err))
         (write-gateway-result "error" "error" (repr $err))
         (println! (string_concat "Gateway Result: Error - " (repr $err)))))

      ((AgentResult max_iterations_exceeded $msg)
       (progn
         (emit-telemetry "response_error" "error" $msg "")
         (write-gateway-result "error" "error" $msg)
         (println! (string_concat "Gateway Result: IterationLimit - " $msg))))

      ((AgentResult unsupported $kind $reason)
       (progn
         (emit-telemetry "response_error" "error" $reason (repr $kind))
         (write-gateway-result "error" "unsupported" $reason)
         (println! (string_concat "Gateway Result: Unsupported - " $reason))))

      ($_
       (progn
         (emit-telemetry "response_error" "error" "Cognitive cycle ended unexpectedly" (repr $res))
         (write-gateway-result "error" "error" "Unable to process request.")
         (println! (string_concat "Gateway Result: Other - " (repr $res))))))))

;; Process validated query
(= (process-gateway-query $query)
   (if (or (== $query "") (== $query " "))
       (progn
         (emit-telemetry "empty_query" "init" "Received empty query from UI" "")
         (write-gateway-result "error" "error" "Please enter a valid non-empty question or task.")
         (println! "Gateway: Empty query."))
       (progn
         (emit-telemetry "request_received" "init" "User request received by PeTTa runtime" $query)
         (let $res (if (== (state-is-awaiting-clarification) true)
                       (resume-after-clarification "default" $query 25)
                       (run-cognitive-cycle "default" $query 25))
           (process-gateway-result $res))
         (state-save-session)
         (memory-shutdown)
         (adaptation-save-to-disk)
         (println! "Gateway: Turn completed successfully."))))

;; Main gateway runner
(= (run-ui-gateway-turn)
   (progn
     (plan-clear-all)
     (memory-init)
     (adaptation-load-from-disk)
     (clear-telemetry)
     (state-load-session)
     (let $query (read-gateway-query)
       (process-gateway-query $query))))

;; Execute gateway turn
!(run-ui-gateway-turn)
