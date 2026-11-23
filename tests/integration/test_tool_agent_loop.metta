;; =============================================================================
;; STAGE C - MILESTONE 7: Tool Cognitive Loop Integration Test
;; File: tests/integration/test_tool_agent_loop.metta
;; =============================================================================

!(println! "=== Starting Tool Agent Cognitive Loop Integration Tests ===")

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "../../agent/loop.metta")

;; Test 1: Direct answer when no tool is needed
!(println! "--- Test 1: Direct Answer Without Tools ---")
!(let $res1 (run-cognitive-cycle "gemini" "What is the capital of Germany?" 5)
   (case $res1
     (((AgentResult answer $ans)
       (progn
         (println! "✅ Direct answer received:")
         (println! $ans)))
      ($_ (println! "Unexpected result in Test 1.")))))

;; Test 2: Multi-step Reasoning with Calculator Tool Execution
!(println! "--- Test 2: Math Calculation via Tool Execution ---")
!(let $res2 (run-cognitive-cycle "gemini" "Compute 125 * 8 using your calculator tool." 5)
   (case $res2
     (((AgentResult answer $ans)
       (progn
         (println! "✅ Tool loop executed and final answer received:")
         (println! $ans)))
      ((AgentResult error $err)
       (progn
         (println! "❌ Tool loop returned error:")
         (println! $err)))
      ($_ (println! "Unexpected result in Test 2.")))))

;; Test 3: String Reverser Tool Execution
!(println! "--- Test 3: String Reverser Tool Execution ---")
!(let $res3 (run-cognitive-cycle "gemini" "Reverse the word 'Hyperon' using your string_reverser tool." 5)
   (case $res3
     (((AgentResult answer $ans)
       (progn
         (println! "✅ String reverser tool loop executed and final answer received:")
         (println! $ans)))
      ($_ (println! "Unexpected result in Test 3.")))))

;; Test 4: Inspection of Tool Execution History
!(println! "--- Test 4: Inspecting Recorded Tool History ---")
!(let $hist (history-list-recent)
   (println! "Recent tool executions recorded in history:"))

!(println! "=== ALL TOOL AGENT LOOP INTEGRATION TESTS COMPLETED ===")
