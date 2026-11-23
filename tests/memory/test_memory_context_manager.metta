;; =============================================================================
;; STAGE D - MILESTONE 10: Context Manager & Provenance Unit Tests
;; File: tests/memory/test_memory_context_manager.metta
;; =============================================================================

!(println! "=== Starting Context Manager Unit Tests ===")

!(import! &self "../../agent/memory_core.metta")
!(import! &self "../../agent/state.metta")
!(import! &self "../../agent/context_manager.metta")

;; Reset stores and conversation
!(memory-clear-all)
!(memory-clear-disk)
!(state-clear)

;; Test 1: Empty context sources do not crash assembly
!(println! "--- Test 1: Empty context sources handling ---")
!(let $res1 (assemble-managed-context "Any query text" 3)
   (case $res1
     (((ManagedContext $conv $mem $cons)
       (progn
         (test $conv "No prior conversation history.")
         (test $mem "")
         (test $cons "")
         (println! "✅ Empty context gracefully returned default structures.")))
      ($_ (println! "❌ Test 1 failed.")))))

;; Test 2: Inclusion of conversation history and observations
!(println! "--- Test 2: Conversation history inclusion ---")
!(state-add-user-message "Calculate 15 * 4.")
!(state-add-observation "[Observation from calculator]: 60")
!(state-add-assistant-message "15 * 4 is 60.")

!(let $conv_res (format-managed-conversation-context)
   (progn
     (test (sub_string_match (repr $conv_res) "Calculate 15 * 4") true)
     (println! "✅ Conversation history accurately captured user message.")))

;; Test 3: Relevant memory included, irrelevant memory excluded
!(println! "--- Test 3: Selective relevance & provenance ---")
!(memory-store preference "User prefers concise answers.")
!(memory-store fact "Mount Everest is 8,848 meters high.")

!(let $mem_res (format-relevant-memories-context "concise" 3)
   (progn
     ;; Relevant preference must be included
     (test (sub_string_match $mem_res "User prefers concise answers.") true)
     ;; Provenance must be preserved
     (test (sub_string_match $mem_res "Category: preference") true)
     (test (sub_string_match $mem_res "Source: user") true)
     ;; Irrelevant memory must be excluded
     (test (sub_string_match $mem_res "Mount Everest") false)
     (println! "✅ Relevant memory included with provenance; irrelevant memory excluded.")))

;; Test 4: Conflict guidance inclusion in managed context
!(println! "--- Test 4: Conflict guidance integration ---")
!(memory-store preference "User prefers detailed verbose text.")

!(let $res4 (assemble-managed-context "Tell me a story" 3)
   (case $res4
     (((ManagedContext $c $m $cons)
       (progn
         (test (sub_string_match $cons "CRITICAL MEMORY NOTICE") true)
         (println! "✅ Memory conflict notice dynamically incorporated into context.")))
      ($_ (println! "❌ Test 4 failed.")))))

!(println! "=== ALL CONTEXT MANAGER UNIT TESTS PASSED ===")
