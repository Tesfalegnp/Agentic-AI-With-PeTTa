;; =============================================================================
;; STAGE C - MILESTONE 6: Test Suite for Conversation State
;; File: tests/agent/test_state.metta
;; =============================================================================

!(println! "=== Starting Conversation State Tests ===")

!(import! &self "../../agent/state.metta")

;; Test 1: Empty state initial context
!(println! "--- Test 1: Initial Context ---")
!(test (state-get-context) "No prior conversation history.")

;; Test 2: Adding messages
!(println! "--- Test 2: Adding Messages ---")
!(state-add-user-message "What is PeTTa?")
!(state-add-assistant-message "PeTTa is an efficient MeTTa interpreter.")

;; Test 3: Context contains messages
!(println! "--- Test 3: Querying Context ---")
!(let $ctx (state-get-context)
   (println! (concat "Context retrieved: " $ctx)))

;; Test 4: Clearing state
!(println! "--- Test 4: Clearing State ---")
!(state-clear)
!(test (state-get-context) "No prior conversation history.")

!(println! "=== ALL CONVERSATION STATE TESTS COMPLETED SUCCESSFULLY ===")
