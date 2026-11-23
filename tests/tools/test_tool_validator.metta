;; =============================================================================
;; STAGE C - MILESTONE 7: Tool Validator Unit Test Suite
;; File: tests/tools/test_tool_validator.metta
;; =============================================================================

!(println! "=== Starting Tool Validator Unit Tests ===")

!(import! &self "../../agent/tool_validator.metta")

;; Test 1: Valid tool call validation
!(println! "--- Test 1: Valid Tool Call Validation ---")
!(test (validate-tool-call calculator ("25 * 4"))
       (ToolValidationSuccess calculator ("25 * 4")))
!(test (validate-tool-call word_counter ("Some text"))
       (ToolValidationSuccess word_counter ("Some text")))
!(test (validate-tool-call datetime ())
       (ToolValidationSuccess datetime ()))

;; Test 2: Unregistered tool rejection
!(println! "--- Test 2: Unregistered Tool Rejection ---")
!(test (validate-tool-call malicious_tool ("rm -rf /"))
       (ToolValidationFailure malicious_tool "Unregistered tool name."))

;; Test 3: Disabled tool rejection
!(println! "--- Test 3: Disabled Tool Rejection ---")
!(disable-tool calculator)
!(test (validate-tool-call calculator ("10 + 20"))
       (ToolValidationFailure calculator "Tool is currently disabled."))
!(enable-tool calculator)

;; Test 4: Missing arguments
!(println! "--- Test 4: Missing Arguments Rejection ---")
!(test (validate-tool-call calculator ())
       (ToolValidationFailure calculator "Calculator requires exactly 1 expression argument."))

;; Test 5: Extra arguments
!(println! "--- Test 5: Extra Arguments Rejection ---")
!(test (validate-tool-call calculator ("10 + 20" "extra_arg"))
       (ToolValidationFailure calculator "Calculator requires exactly 1 expression argument."))

!(println! "=== TOOL VALIDATOR UNIT TESTS COMPLETED SUCCESSFULLY ===")
