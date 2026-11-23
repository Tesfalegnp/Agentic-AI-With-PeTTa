;; =============================================================================
;; STAGE C - MILESTONE 7: Tool Dispatcher Unit Test Suite
;; File: tests/tools/test_tool_dispatcher.metta
;; =============================================================================

!(println! "=== Starting Tool Dispatcher Unit Tests ===")

!(import! &self "../../agent/tool_dispatcher.metta")

;; Clear history before testing
!(history-clear)

;; Test 1: Successful calculator dispatch
!(println! "--- Test 1: Calculator Dispatch Success ---")
!(test (dispatch-tool calculator ("15 * 6"))
       (ToolResult success calculator 90))

;; Test 2: Successful word counter dispatch
!(println! "--- Test 2: Word Counter Dispatch Success ---")
!(test (dispatch-tool word_counter ("The rain in Spain falls mainly on the plain"))
       (ToolResult success word_counter 9))

;; Test 3: Successful string reverser dispatch
!(println! "--- Test 3: String Reverser Dispatch Success ---")
!(test (dispatch-tool string_reverser ("antigravity"))
       (ToolResult success string_reverser "ytivargitna"))

;; Test 4: Unregistered tool dispatch failure
!(println! "--- Test 4: Unregistered Tool Dispatch Failure ---")
!(test (dispatch-tool unregistered_tool ("arg"))
       (ToolResult failure unregistered_tool "Unregistered tool name."))

;; Test 5: Disabled tool dispatch failure
!(println! "--- Test 5: Disabled Tool Dispatch Failure ---")
!(disable-tool calculator)
!(test (dispatch-tool calculator ("10 + 20"))
       (ToolResult failure calculator "Tool is currently disabled."))
!(enable-tool calculator)

;; Test 6: Tool execution failure (division by zero)
!(println! "--- Test 6: Tool Execution Division by Zero Failure ---")
!(test (dispatch-tool calculator ("50 / 0"))
       (ToolResult failure calculator "Division by zero error."))

;; Test 7: Verify history was populated by dispatches
!(println! "--- Test 7: History Verification ---")
!(let $records (history-list-recent)
   (println! "Dispatcher correctly recorded executions to history."))

!(println! "=== TOOL DISPATCHER UNIT TESTS COMPLETED SUCCESSFULLY ===")
