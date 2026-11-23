;; =============================================================================
;; STAGE C - MILESTONE 6: End-to-End Live Agent Integration Test
;; File: tests/integration/test_live_agent.metta
;; =============================================================================

!(println! "=== Starting Live Agent Cognitive Loop Integration Test ===")

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "../../agent/loop.metta")

!(println! "--- Step 1: Submitting Real Query to Cognitive Loop ---")
!(let $result (run-cognitive-cycle "gemini" "What is the capital of Japan?" 5)
   (case $result
     (((AgentResult answer $ans)
       (progn
         (println! "✅ Live Agent Successfully Answered:")
         (println! $ans)))
      ((AgentResult ask_user $q)
       (progn
         (println! "ℹ️ Live Agent Asked User:")
         (println! $q)))
      ((AgentResult finish $sum)
       (progn
         (println! "🏁 Live Agent Finished Task:")
         (println! $sum)))
      ((AgentResult error $err)
       (progn
         (println! "❌ Live Agent Returned Error:")
         (println! $err)))
      ($_
       (println! "⚠️ Unexpected Agent Result.")))))

!(println! "=== LIVE AGENT INTEGRATION TEST COMPLETED ===")
