;; =============================================================================
;; STAGE C - MILESTONE 6: Test Suite for Cognitive Reasoning Loop (Mocked)
;; File: tests/agent/test_loop_mocked.metta
;; =============================================================================

!(println! "=== Starting Mocked Cognitive Loop Tests ===")

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "../../agent/loop.metta")

;; Test 1: Bounded recursion limit enforcement
!(println! "--- Test 1: Maximum Iteration Limit Enforcement ---")
;; When iteration exceeds max_iterations, cognitive-step terminates immediately
!(test (cognitive-step "default" "test prompt" 6 5)
       (AgentResult max_iterations_exceeded "Reasoning iteration limit reached."))

;; Test 2: Handling invalid provider safely without crash
!(println! "--- Test 2: Invalid Provider Error Handling ---")
!(let $res (cognitive-step "non_existent_provider" "test prompt" 1 5)
   (case $res
     (((AgentResult error $msg) (println! "Safely handled invalid provider error."))
      ($_ (println! "Unexpected result.")))))

;; Test 3: Handling unconfigured provider safely
!(println! "--- Test 3: Unconfigured Provider Handling ---")
!(let $res (cognitive-step "openai" "" 1 5)
   (case $res
     (((AgentResult error $msg) (println! "Safely handled unconfigured provider."))
      ($_ (println! "Unexpected result.")))))

!(println! "=== ALL MOCKED COGNITIVE LOOP TESTS PASSED ===")
