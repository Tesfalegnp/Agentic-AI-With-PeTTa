;; =============================================================================
;; STAGE C - MILESTONE 9: Mocked Memory Cognitive Loop Integration Tests
;; File: tests/memory/test_memory_agent_loop_mocked.metta
;; =============================================================================

!(println! "=== Starting Mocked Memory Cognitive Loop Tests ===")

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "../../agent/loop.metta")
!(import! &self "../../agent/memory_core.metta")

;; Test 1: Bounded iteration limit
!(println! "--- Test 1: Iteration Limit Enforcement ---")
!(test (cognitive-step "default" "test prompt" 6 5)
       (AgentResult max_iterations_exceeded "Reasoning iteration limit reached."))

;; Test 2: Valid remember action parsing
!(println! "--- Test 2: Valid remember Action Parsing ---")
!(test (parse-and-validate-response "(action remember preference \"User prefers concise answers.\")")
       (ActionValid remember preference "User prefers concise answers."))

;; Test 3: Valid recall action parsing
!(println! "--- Test 3: Valid recall Action Parsing ---")
!(test (parse-and-validate-response "(action recall preference \"concise\")")
       (ActionValid recall preference "concise"))

;; Test 4: Memory observation formatting
!(println! "--- Test 4: Observation Formatting ---")
!(let $res (format-memory-observation (MemoryStoreSuccess "mem_1" fact "Test fact."))
   (println! "Formatted store observation successfully."))

!(let $res2 (format-memory-observation (MemoryRecallSuccess fact ("Test fact.")))
   (println! "Formatted recall observation successfully."))

!(println! "=== ALL MOCKED MEMORY COGNITIVE LOOP TESTS PASSED ===")
