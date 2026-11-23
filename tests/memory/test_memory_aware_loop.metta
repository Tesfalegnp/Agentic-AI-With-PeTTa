;; =============================================================================
;; STAGE D - MILESTONE 10: Memory-Aware Cognitive Loop Unit Tests
;; File: tests/memory/test_memory_aware_loop.metta
;; =============================================================================

!(println! "=== Starting Memory-Aware Cognitive Loop Tests ===")

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "../../agent/prompt.metta")
!(import! &self "../../agent/loop.metta")
!(import! &self "../../agent/state.metta")
!(import! &self "../../agent/memory_core.metta")
!(import! &self "../../agent/memory_store.metta")
!(import! &self "../../agent/memory_ranking.metta")
!(import! &self "../../agent/memory_consistency.metta")

;; Reset memory and state for clean test run
!(memory-reset-all)
!(state-reset)

;; -----------------------------------------------------------------------------
;; Test 1: Memory-Aware Context Assembly in Prompt Construction
;; -----------------------------------------------------------------------------
!(println! "--- Test 1: Relevant Memory Automatically Injected into Prompt ---")
!(memory-store preference "User prefers concise answers.")
!(memory-store fact "Target programming language is Rust.")

!(let* (($ctx (state-get-context))
        ($prompt (build-agent-prompt $ctx "How should you format your answers?")))
   (progn
     (test (sub_string_match $prompt "RELEVANT RETRIEVED MEMORIES") true)
     (test (sub_string_match $prompt "User prefers concise answers.") true)
     (test (sub_string_match $prompt "[Memory ID:") true)
     (println! "Test 1 PASSED: Memory-aware prompt contains verified memory with provenance.")))

;; -----------------------------------------------------------------------------
;; Test 2: Irrelevant Memories Filtered Out of Prompt
;; -----------------------------------------------------------------------------
!(println! "--- Test 2: Irrelevant Memory Not Injected into Prompt ---")
!(let* (($ctx (state-get-context))
        ($prompt (build-agent-prompt $ctx "What is the capital of France?")))
   (progn
     ;; With no query overlap, prompt should NOT include the Rust or concise memory
     (test (sub_string_match $prompt "Target programming language is Rust.") false)
     (println! "Test 2 PASSED: Irrelevant memory was correctly filtered out.")))

;; -----------------------------------------------------------------------------
;; Test 3: Contradictory Preference Notice in Prompt
;; -----------------------------------------------------------------------------
!(println! "--- Test 3: Conflict Notice Guidance in Prompt ---")
!(memory-store preference "User prefers detailed, extensive explanations.")
!(let* (($ctx (state-get-context))
        ($prompt (build-agent-prompt $ctx "Explain recursion.")))
   (progn
     (test (sub_string_match $prompt "CRITICAL MEMORY NOTICE") true)
     (test (sub_string_match $prompt "ask_user") true)
     (println! "Test 3 PASSED: Prompt includes conflict warning directing agent to ask_user.")))

;; -----------------------------------------------------------------------------
;; Test 4: Action Parsing in Memory-Aware Cognitive Scenarios
;; -----------------------------------------------------------------------------
!(println! "--- Test 4: Action Validation Across Memory Scenarios ---")

;; 4a: Answering using remembered preference
!(let $act_answer (parse-and-validate-response "(action answer \"Recursion is a method of solving problems where a function calls itself.\")")
   (case $act_answer
     (((ActionValid answer $txt)
       (println! "Test 4a PASSED: Direct answer parsed successfully."))
      ($_ (test "expected ActionValid answer" "failed")))))

;; 4b: Resolving memory conflict via ask_user
!(let $act_clarify (parse-and-validate-response "(action ask_user \"I noticed conflicting preferences for answer detail (concise vs detailed). Which style do you prefer?\")")
   (case $act_clarify
     (((ActionValid ask_user $q)
       (println! "Test 4b PASSED: Clarification via ask_user parsed successfully."))
      ($_ (test "expected ActionValid ask_user" "failed")))))

;; 4c: Graceful answer with no relevant memory (avoiding hallucination)
!(let $act_empty (parse-and-validate-response "(action answer \"I do not have any stored information about your database schema yet.\")")
   (case $act_empty
     (((ActionValid answer $txt)
       (println! "Test 4c PASSED: Non-hallucinatory response parsed successfully."))
      ($_ (test "expected ActionValid answer" "failed")))))

;; -----------------------------------------------------------------------------
;; Test 5: Loop Bounded Execution Guard
;; -----------------------------------------------------------------------------
!(println! "--- Test 5: Iteration Limit Guard ---")
!(test (cognitive-step "mock_provider" "test prompt" 6 5)
       (AgentResult max_iterations_exceeded "Reasoning iteration limit reached."))
!(println! "Test 5 PASSED: Cognitive loop iteration limit enforced.")

!(println! "=== ALL MEMORY-AWARE COGNITIVE LOOP TESTS PASSED ===")
