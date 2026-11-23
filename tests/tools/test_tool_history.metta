;; =============================================================================
;; STAGE C - MILESTONE 7: Tool Execution History Unit Test Suite
;; File: tests/tools/test_tool_history.metta
;; =============================================================================

!(println! "=== Starting Tool Execution History Unit Tests ===")

!(import! &self "../../agent/tool_history.metta")

;; Test 1: Clear history
!(println! "--- Test 1: Clear Initial History ---")
!(history-clear)
!(test (history-list-recent) ())

;; Test 2: Add successful execution record
!(println! "--- Test 2: Record Successful Call ---")
!(test (history-record-tool-call calculator ("25 * 4") success "100")
       (HistoryRecorded 1 calculator))

;; Test 3: Add failed execution record
!(println! "--- Test 3: Record Failed Call ---")
!(test (history-record-tool-call calculator ("100 / 0") failure "Division by zero error.")
       (HistoryRecorded 2 calculator))

;; Test 4: Retrieve records by tool name
!(println! "--- Test 4: Retrieve By Tool ---")
!(let $calc_history (history-get-by-tool calculator)
   (println! "Retrieved history by tool successfully."))

;; Test 5: Reset and clear
!(println! "--- Test 5: Reset History ---")
!(history-clear)
!(test (history-list-recent) ())

!(println! "=== TOOL HISTORY UNIT TESTS COMPLETED SUCCESSFULLY ===")
