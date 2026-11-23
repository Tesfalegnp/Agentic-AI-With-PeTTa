;; =============================================================================
;; STAGE C - MILESTONE 8: Live Gemini Skill Cognitive Loop Integration Test
;; File: tests/integration/test_skill_agent_loop.metta
;; =============================================================================

!(println! "=== Starting Live Gemini Skill Cognitive Loop Integration Tests ===")

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "../../agent/loop.metta")
!(import! &self "../../agent/skill_history.metta")
!(import! &self "../../agent/tool_history.metta")

;; Test 1: Direct answer when no skill/tool is needed
!(println! "--- Test 1: Direct Answer Without Skills ---")
!(let $res1 (run-cognitive-cycle "gemini" "What is the capital of Japan?" 5)
   (case $res1
     (((AgentResult answer $ans)
       (progn
         (println! "✅ Direct answer received:")
         (println! $ans)))
      ($_ (println! "Unexpected result in Test 1.")))))

;; Test 2: Direct Tool Execution (Preserve Milestone 7)
!(println! "--- Test 2: Calculator Tool Direct Execution ---")
!(let $res2 (run-cognitive-cycle "gemini" "Calculate 50 * 6 using your calculator tool." 5)
   (case $res2
     (((AgentResult answer $ans)
       (progn
         (println! "✅ Calculator tool loop executed and final answer received:")
         (println! $ans)))
      ($_ (println! "Unexpected result in Test 2.")))))

;; Test 3: Multi-step Math Skill Execution
!(println! "--- Test 3: Math Skill Execution via Agent Loop ---")
!(let $res3 (run-cognitive-cycle "gemini" "Use your math_skill to calculate 125 * 8." 5)
   (case $res3
     (((AgentResult answer $ans)
       (progn
         (println! "✅ Math skill loop executed and final answer received:")
         (println! $ans)))
      ((AgentResult error $err)
       (progn
         (println! "❌ Math skill loop returned error:")
         (println! $err)))
      ($_ (println! "Unexpected result in Test 3.")))))

;; Test 4: Inspection of Skill and Tool Histories
!(println! "--- Test 4: Inspecting Recorded Skill and Tool History ---")
!(let $sk_hist (skill-history-list)
   (println! "Skill history entries recorded."))
!(let $tl_hist (history-list-recent)
   (println! "Tool history entries recorded."))

!(println! "=== ALL LIVE SKILL AGENT LOOP INTEGRATION TESTS COMPLETED ===")
