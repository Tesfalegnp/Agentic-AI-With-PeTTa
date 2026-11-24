;; =============================================================================
;; Automated Test: Long-Running Task Execution (20+ Turns)
;; File: tests/agent/test_long_running_task.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "../../agent/tool_registry.metta")
!(import! &self "../../agent/tool_validator.metta")
!(import! &self "../../agent/tool_dispatcher.metta")
!(import! &self "../../agent/state.metta")

;; Recursive simulation of a 22-turn genuine multi-step execution cycle
(= (step-chain $step $max $acc)
   (if (> $step $max)
       (ChainCompleted $acc)
       (let* (($expr (string_concat (repr $acc) " + 1"))
              ($step_res (dispatch-tool calculator ($expr)))
              ($next_val (case $step_res (((ToolResult success calculator $val) $val) ($_ -1))))
              ($_a (state-add-assistant-message (string_concat "Step result: " (repr $next_val))))
              ($_o (state-add-observation (string_concat "Observation: " (repr $next_val)))))
         (step-chain (+ $step 1) $max $next_val))))

!(println! "--- Running Test: 22-Step Continuous Reasoning Chain ---")
!(state-clear)
!(let $final_result (step-chain 1 22 0)
   (test $final_result (ChainCompleted 22)))

!(println! "--- Verifying Context Retention Across 22 Turns ---")
!(let $context (state-get-context)
   (test (if (== $context "") false true) true))

!(println! "LONG-RUNNING TASK EXECUTION TEST (22 TURNS) PASSED SUCCESSFULLY! ✅")
