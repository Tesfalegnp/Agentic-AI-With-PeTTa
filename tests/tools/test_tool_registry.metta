;; =============================================================================
;; STAGE C - MILESTONE 7: Tool Registry Unit Test Suite
;; File: tests/tools/test_tool_registry.metta
;; =============================================================================

!(println! "=== Starting Tool Registry Unit Tests ===")

!(import! &self "../../agent/tool_registry.metta")

;; Test 1: Built-in tools are registered
!(println! "--- Test 1: Built-in Tools Registration Verification ---")
!(test (is-tool-registered calculator) true)
!(test (is-tool-registered word_counter) true)
!(test (is-tool-registered text_analyzer) true)
!(test (is-tool-registered string_reverser) true)
!(test (is-tool-registered datetime) true)
!(test (is-tool-registered non_existent_tool) false)

;; Test 2: Built-in tools are enabled by default
!(println! "--- Test 2: Enabled Status Verification ---")
!(test (is-tool-enabled calculator) true)
!(test (is-tool-enabled datetime) true)

;; Test 3: Disabling and re-enabling a tool
!(println! "--- Test 3: Disabling and Enabling Tools ---")
!(disable-tool calculator)
!(test (is-tool-enabled calculator) false)
!(enable-tool calculator)
!(test (is-tool-enabled calculator) true)

;; Test 4: Duplicate registration rejection
!(println! "--- Test 4: Duplicate Registration Handling ---")
!(test (register-tool calculator "Duplicate" () number true)
       (RegistrationDuplicate calculator))

;; Test 5: Dynamic prompt formatting
!(println! "--- Test 5: Prompt Formatting ---")
!(let $prompt_tools (format-tools-for-prompt)
   (println! "Prompt tools successfully formatted."))

!(println! "=== TOOL REGISTRY UNIT TESTS COMPLETED SUCCESSFULLY ===")
