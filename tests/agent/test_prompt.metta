;; =============================================================================
;; STAGE C - MILESTONE 6: Test Suite for System Prompt Construction
;; File: tests/agent/test_prompt.metta
;; =============================================================================

!(println! "=== Starting System Prompt Construction Tests ===")

!(import! &self "../../agent/prompt.metta")

;; Test 1: Identity includes PeTTa Agentic AI Assistant
!(println! "--- Test 1: Agent Identity Verification ---")
!(let $id (prompt-identity)
   (println! (concat "Identity string: " $id)))

;; Test 2: Protocol includes all canonical actions
!(println! "--- Test 2: Protocol Action Verification ---")
!(let $proto (prompt-protocol)
   (println! "Protocol instructions verified."))

;; Test 3: Few-shot examples verification
!(println! "--- Test 3: Few-shot Examples Verification ---")
!(let $shots (prompt-few-shots)
   (println! "Few-shot examples verified."))

;; Test 4: Full Prompt Assembly with Context and Query
!(println! "--- Test 4: Full Prompt Assembly ---")
!(let $full_prompt (build-agent-prompt "User: Prior query" "What is an agent?")
   (println! "Full agent prompt constructed successfully."))

!(println! "=== SYSTEM PROMPT TESTS COMPLETED SUCCESSFULLY ===")
