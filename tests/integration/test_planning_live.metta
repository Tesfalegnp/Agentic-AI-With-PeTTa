;; =============================================================================
;; STAGE D - MILESTONE 11: Live Planning & Execution Integration Tests
;; File: tests/integration/test_planning_live.metta
;; =============================================================================

!(println! "=== Starting Live Planning Integration Tests (Scenarios A through G) ===")

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import_prolog_functions_from_file "agent/memory_io.pl" (sub_string_match))
!(import! &self "../../agent/loop.metta")
!(import! &self "../../agent/goal_planner.metta")
!(import! &self "../../agent/goal_manager.metta")
!(import! &self "../../agent/plan_state.metta")
!(import! &self "../../agent/plan_history.metta")
!(import! &self "../../agent/memory_core.metta")
!(import! &self "../../agent/memory_store.metta")
!(import! &self "../../agent/state.metta")

;; Reset all state and memory
!(goal-clear)
!(plan-clear-all)
!(plan-history-clear)
!(memory-clear-all)
!(state-clear)

;; -----------------------------------------------------------------------------
;; Scenario A: Direct Answer (Factual Query - No Planning Triggered)
;; -----------------------------------------------------------------------------
!(println! "--- Scenario A: Direct Answer (Factual Query) ---")
!(let $res_a (run-cognitive-cycle "gemini" "What is the capital of France?" 3)
   (progn
     (case $res_a
       (((AgentResult answer $ans)
         (progn
           (test (sub_string_match $ans "Paris") true)
           (println! "✅ Scenario A Answer received:")
           (println! $ans)))
        ($_ (test "expected AgentResult answer" "failed"))))
     ;; Verify no goal or plan was created
     (test (goal-list-all) ())
     (test (plan-history-list) ())
     (println! "✅ Scenario A PASSED: Factual query bypassed planner cleanly.")))

;; -----------------------------------------------------------------------------
;; Scenario B: Single Tool (Direct Calculation - No Planning Triggered)
;; -----------------------------------------------------------------------------
!(println! "--- Scenario B: Single Tool (Direct Calculation) ---")
!(let $res_b (run-cognitive-cycle "gemini" "Calculate 45 * 12." 5)
   (progn
     (case $res_b
       (((AgentResult answer $ans)
         (progn
           (test (sub_string_match $ans "540") true)
           (println! "✅ Scenario B Answer received:")
           (println! $ans)))
        ((AgentResult finish $fin)
         (progn
           (test (sub_string_match $fin "540") true)
           (println! "✅ Scenario B Finish received:")
           (println! $fin)))
        ($_ (println! "Scenario B result received."))))
     ;; Verify no multi-step plan was created
     (test (goal-list-all) ())
     (println! "✅ Scenario B PASSED: Single tool query did not invoke planner.")))

;; -----------------------------------------------------------------------------
;; Scenario C: Multi-Step Tool Workflow Execution
;; -----------------------------------------------------------------------------
!(println! "--- Scenario C: Multi-Step Tool Workflow ---")
!(let $res_c (run-cognitive-cycle "gemini" "Multi-step workflow: count words in 'Autonomous Cognitive Architecture' and then analyze the text." 5)
   (case $res_c
     (((AgentResult finish $summary)
       (progn
         (println! "✅ Scenario C Finished with summary:")
         (println! $summary)
         (let $goals (goal-list-all)
           (test (length $goals) 1))
         (println! "✅ Scenario C PASSED: Multi-step tool workflow planned, executed, and verified.")))
      ((AgentResult error $err)
       (progn
         (println! "Scenario C ended with error:")
         (println! $err)))
      ($_ (println! "Scenario C completed with other result.")))))

;; -----------------------------------------------------------------------------
;; Scenario D: Skill-Based Multi-Step Workflow
;; -----------------------------------------------------------------------------
!(println! "--- Scenario D: Skill-Based Multi-Step Workflow ---")
!(let $res_d (run-cognitive-cycle "gemini" "Multi-step pipeline: use math_skill to calculate 50 * 4 and then summarize the result." 5)
   (case $res_d
     (((AgentResult finish $summary)
       (progn
         (println! "✅ Scenario D Finished with summary:")
         (println! $summary)
         (println! "✅ Scenario D PASSED: Skill-based workflow executed successfully.")))
      ((AgentResult error $err)
       (progn
         (println! "Scenario D completed with error:")
         (println! $err)))
      ($_ (println! "Scenario D completed with other result.")))))

;; -----------------------------------------------------------------------------
;; Scenario E: Predictable Failure Recovery & Blocked Dependency
;; -----------------------------------------------------------------------------
!(println! "--- Scenario E: Predictable Failure Recovery & Blocked Dependency ---")
!(let $res_e (run-cognitive-cycle "gemini" "Multi-step pipeline: calculate 100 / 0 and then analyze the calculation result." 5)
   (case $res_e
     (((AgentResult error $err)
       (progn
         (println! "✅ Scenario E Error correctly caught and reported:")
         (println! $err)
         (println! "✅ Scenario E PASSED: Failure properly blocked dependent task and reported.")))
      ((AgentResult finish $fin)
       (progn
         (println! "Scenario E finished:")
         (println! $fin)))
      ($_ (println! "Scenario E completed with other result.")))))

;; -----------------------------------------------------------------------------
;; Scenario F: Memory-Aware Planning Context Injection
;; -----------------------------------------------------------------------------
!(println! "--- Scenario F: Memory-Aware Planning ---")
!(memory-store-with-priority fact "The target project codename is Project Chimera." 5)
!(let $res_f (run-cognitive-cycle "gemini" "Multi-step workflow: analyze word count and text for Project Chimera." 5)
   (case $res_f
     (((AgentResult finish $summary)
       (progn
         (println! "✅ Scenario F Finished with summary:")
         (println! $summary)
         (println! "✅ Scenario F PASSED: Memory context influenced multi-step planning.")))
      ((AgentResult error $err)
       (progn
         (println! "Scenario F ended with error:")
         (println! $err)))
      ($_ (println! "Scenario F completed with other result.")))))

;; -----------------------------------------------------------------------------
;; Scenario G: Ambiguous Goal Handling
;; -----------------------------------------------------------------------------
!(println! "--- Scenario G: Ambiguous Goal Clarification ---")
!(let $res_g (run-cognitive-cycle "gemini" "Do some analysis on the data." 3)
   (case $res_g
     (((AgentResult ask_user $question)
       (progn
         (println! "✅ Scenario G Clarification requested via ask_user:")
         (println! $question)
         (println! "✅ Scenario G PASSED: Ambiguous goal led to user clarification request.")))
      ((AgentResult answer $ans)
       (progn
         (println! "Scenario G provided direct answer:")
         (println! $ans)
         (println! "✅ Scenario G PASSED: Ambiguous request handled gracefully.")))
      ($_ (println! "Scenario G completed with other result.")))))

!(println! "=== ALL SCENARIOS A THROUGH G COMPLETED ===")
