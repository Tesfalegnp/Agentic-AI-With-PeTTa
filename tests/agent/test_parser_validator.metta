;; =============================================================================
;; STAGE C - MILESTONE 9: Test Suite for Response Parser and Action Validator
;; File: tests/agent/test_parser_validator.metta
;; =============================================================================

!(println! "=== Starting Response Parser & Action Validator Tests ===")

!(import! &self "../../agent/response_parser.metta")
!(import! &self "../../agent/action_validator.metta")

;; Test 1: Valid 'answer' action
!(println! "--- Test 1: Valid answer action ---")
!(test (parse-and-validate-response "(action answer \"The capital of France is Paris.\")")
       (ActionValid answer "The capital of France is Paris."))

;; Test 2: Valid 'ask_user' action
!(println! "--- Test 2: Valid ask_user action ---")
!(test (parse-and-validate-response "(action ask_user \"Which file would you like to inspect?\")")
       (ActionValid ask_user "Which file would you like to inspect?"))

;; Test 3: Valid 'finish' action
!(println! "--- Test 3: Valid finish action ---")
!(test (parse-and-validate-response "(action finish \"Goal successfully achieved.\")")
       (ActionValid finish "Goal successfully achieved."))

;; Test 4: Valid 'error' action
!(println! "--- Test 4: Valid error action ---")
!(test (parse-and-validate-response "(action error \"Rate limit or internal error occurred.\")")
       (ActionValid error "Rate limit or internal error occurred."))

;; Test 5: Markdown code-fence stripping
!(println! "--- Test 5: Markdown code fence stripping ---")
!(test (parse-and-validate-response "```metta\n(action answer \"Wrapped in code fence\")\n```")
       (ActionValid answer "Wrapped in code fence"))

;; Test 6: Extra surrounding conversational text rejected safely or extracted
!(println! "--- Test 6: Surrounding text handling ---")
!(test (parse-and-validate-response "Here is the result: (action answer \"Extracted from chatter\") hope that helps!")
       (ActionValid answer "Extracted from chatter"))

;; Test 7: Active capability 'use_tool' validated as ActionValid
!(println! "--- Test 7: Active use_tool capability ---")
!(test (parse-and-validate-response "(action use_tool calculator (add 5 10))")
       (ActionValid use_tool calculator (add 5 10)))

;; Test 8: Active capability 'use_skill' validated as ActionValid (Milestone 8)
!(println! "--- Test 8: Active use_skill capability ---")
!(test (parse-and-validate-response "(action use_skill research_skill (search \"PeTTa\"))")
       (ActionValid use_skill research_skill (search "PeTTa")))

;; Test 9: Active capability 'remember' validated as ActionValid (Milestone 9)
!(println! "--- Test 9: Active remember capability ---")
!(test (parse-and-validate-response "(action remember preference \"User prefers concise answers\")")
       (ActionValid remember preference "User prefers concise answers"))

;; Test 10: Active capability 'recall' validated as ActionValid (Milestone 9)
!(println! "--- Test 10: Active recall capability ---")
!(test (parse-and-validate-response "(action recall preference \"concise\")")
       (ActionValid recall preference "concise"))

;; Test 11: Invalid action name rejected
!(println! "--- Test 11: Unknown action name rejection ---")
!(test (parse-and-validate-response "(action execute_bash \"rm -rf /\")")
       (ActionError (ValidationFailed "Unrecognized action structure or non-conforming protocol syntax.")))

;; Test 12: Empty response rejected
!(println! "--- Test 12: Empty response rejection ---")
!(test (parse-and-validate-response "")
       (ActionError (MalformedResponse (empty_response "LLM returned an empty content string."))))

;; Test 13: Malformed syntax rejected safely
!(println! "--- Test 13: Malformed parentheses rejection ---")
!(let $res (parse-and-validate-response "(action answer \"unterminated string)")
   (case $res
     (((ActionError (MalformedResponse $err)) (println! "Safely caught malformed syntax."))
      ($_ (println! "Unexpected parse result.")))))

!(println! "=== ALL PARSER & VALIDATOR TESTS COMPLETED SUCCESSFULLY ===")
