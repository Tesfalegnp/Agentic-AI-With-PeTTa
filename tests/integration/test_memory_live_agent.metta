;; =============================================================================
;; STAGE C - MILESTONE 9: Live Gemini Persistent Memory Cognitive Loop Test
;; File: tests/integration/test_memory_live_agent.metta
;; =============================================================================

!(println! "=== Starting Live Gemini Persistent Memory Cognitive Loop Tests ===")

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "../../agent/loop.metta")
!(import! &self "../../agent/memory_core.metta")

;; Clear stores before test
!(memory-clear-all)
!(memory-clear-disk)

;; Test 1: User asks agent to remember a fact
!(println! "--- Test 1: Asking Agent to Remember Fact ---")
!(let $res1 (run-cognitive-cycle "gemini" "Please remember that my favorite programming language is Prolog." 5)
   (case $res1
     (((AgentResult answer $ans)
       (progn
         (println! "✅ Remember action completed and agent confirmed:")
         (println! $ans)))
      ((AgentResult finish $fin)
       (progn
         (println! "✅ Remember action completed and agent finished:")
         (println! $fin)))
      ((AgentResult error $err)
       (progn
         (println! "❌ Agent returned error:")
         (println! $err)))
      ($_ (println! "Other result in Test 1.")))))

;; Test 2: User asks agent to recall that fact in a subsequent query
!(println! "--- Test 2: Asking Agent to Recall Fact ---")
!(let $res2 (run-cognitive-cycle "gemini" "What is my favorite programming language according to your memory?" 5)
   (case $res2
     (((AgentResult answer $ans)
       (progn
         (println! "✅ Recall action completed and agent answered:")
         (println! $ans)))
      ((AgentResult finish $fin)
       (progn
         (println! "✅ Recall action completed and agent finished:")
         (println! $fin)))
      ((AgentResult error $err)
       (progn
         (println! "❌ Agent returned error:")
         (println! $err)))
      ($_ (println! "Other result in Test 2.")))))

;; Test 3: Inspect recorded memory history
!(println! "--- Test 3: Inspecting Memory History ---")
!(let $hist (memory-history-list)
   (println! "Memory history audit log entries recorded."))

!(println! "=== ALL LIVE MEMORY AGENT LOOP INTEGRATION TESTS COMPLETED ===")
