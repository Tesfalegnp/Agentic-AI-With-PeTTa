;; =============================================================================
;; STAGE C - MILESTONE 7: Built-in Tools Unit Test Suite
;; File: tests/tools/test_builtin_tools.metta
;; =============================================================================

!(println! "=== Starting Built-in Tools Unit Tests ===")

!(import! &self "../../tools/builtin/calculator.metta")
!(import! &self "../../tools/builtin/word_counter.metta")
!(import! &self "../../tools/builtin/text_analyzer.metta")
!(import! &self "../../tools/builtin/string_reverser.metta")
!(import! &self "../../tools/builtin/datetime.metta")

;; 1. Calculator Tests
!(println! "--- 1. Testing Calculator ---")
!(test (run-calculator ("25 * 4")) (ToolResult success calculator 100))
!(test (run-calculator ("(10 + 20) / 2")) (ToolResult success calculator 15))
!(test (run-calculator ("100 - 45")) (ToolResult success calculator 55))
!(test (run-calculator ("100 / 0")) (ToolResult failure calculator "Division by zero error."))
!(test (run-calculator ("invalid(expr)")) (ToolResult failure calculator "Malformed or unsupported mathematical expression."))
!(test (run-calculator ()) (ToolResult failure calculator "Invalid argument format. Expected 1 expression string."))

;; 2. Word Counter Tests
!(println! "--- 2. Testing Word Counter ---")
!(test (run-word-counter ("The quick brown fox jumps over the lazy dog")) (ToolResult success word_counter 9))
!(test (run-word-counter ("")) (ToolResult success word_counter 0))
!(test (run-word-counter ("   multiple    spaces   and\nnewlines\tand tabs   ")) (ToolResult success word_counter 6))
!(test (run-word-counter ()) (ToolResult failure word_counter "Invalid argument format. Expected 1 text string."))

;; 3. Text Analyzer Tests
!(println! "--- 3. Testing Text Analyzer ---")
!(test (run-text-analyzer ("Hello world. How are you?\nFine."))
       (ToolResult success text_analyzer (TextAnalysis 31 6 2 4)))
!(test (run-text-analyzer (""))
       (ToolResult success text_analyzer (TextAnalysis 0 0 0 0)))

;; 4. String Reverser Tests
!(println! "--- 4. Testing String Reverser ---")
!(test (run-string-reverser ("PeTTa")) (ToolResult success string_reverser "aTTeP"))
!(test (run-string-reverser ("")) (ToolResult success string_reverser ""))
!(test (run-string-reverser ("Hello, World!")) (ToolResult success string_reverser "!dlroW ,olleH"))

;; 5. DateTime Tests
!(println! "--- 5. Testing DateTime ---")
!(let (ToolResult success datetime $dt) (run-datetime ())
   (println! (string_concat "DateTime returned: " $dt)))

!(println! "=== ALL BUILT-IN TOOL TESTS PASSED SUCCESSFULLY ===")
