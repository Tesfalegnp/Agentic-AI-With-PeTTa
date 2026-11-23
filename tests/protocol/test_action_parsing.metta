; ==============================================================================
; Task 3.6: Structured LLM Action Parsing & Validation Feasibility Test
; ==============================================================================

!(println! "=== Starting Task 3.6: Action Parsing Feasibility Test ===")

; Registered tools mock registry with case
(= (is-registered-tool $t)
   (case $t
     ((calculator true)
      (word_counter true)
      (text_analyzer true)
      ($_ false))))

; Registered skills mock registry with case
(= (is-registered-skill $s)
   (case $s
     ((math_skill true)
      (research_skill true)
      ($_ false))))

; Safe sread with error trapping
(= (safe-parse $str)
   (case (catch (sread $str))
     (((Error $type $msg) (ParseError $msg))
      ($valid $valid))))

; Semantic Action Validator with case
(= (validate-action $expr)
   (case $expr
     (((action answer $text) (ValidAction answer $text))
      ((action use_tool $tool $args)
       (if (is-registered-tool $tool)
           (ValidAction use_tool $tool $args)
           (InvalidAction (UnregisteredTool $tool))))
      ((action use_skill $skill $args)
       (if (is-registered-skill $skill)
           (ValidAction use_skill $skill $args)
           (InvalidAction (UnregisteredSkill $skill))))
      ((action remember $category $content)
       (ValidAction remember $category $content))
      ((action recall $category $query)
       (ValidAction recall $category $query))
      ((action finish $message)
       (ValidAction finish $message))
      ((action ask_user $question)
       (ValidAction ask_user $question))
      ((action error $reason)
       (ValidAction error $reason))
      ($_ (InvalidAction "Unknown or malformed action structure")))))

; Full parse-and-validate pipeline
(= (process-llm-response $raw_str)
   (let $parsed (safe-parse $raw_str)
     (case $parsed
       (((ParseError $err) (RejectedSyntax $err))
        ($expr (validate-action $expr))))))

; --- Test 1: Valid 'answer' action ---
!(println! "--- Test 1: Valid 'answer' action ---")
!(test (process-llm-response "(action answer \"The result is 42\")")
       (ValidAction answer "The result is 42"))

; --- Test 2: Valid 'use_tool' action with registered tool ---
!(println! "--- Test 2: Valid 'use_tool' action with registered tool ---")
!(test (process-llm-response "(action use_tool calculator (add 10 20))")
       (ValidAction use_tool calculator (add 10 20)))

; --- Test 3: Rejection of unregistered tool name ---
!(println! "--- Test 3: Rejection of unregistered tool name ---")
!(test (process-llm-response "(action use_tool malicious_code_exec (rm -rf))")
       (InvalidAction (UnregisteredTool malicious_code_exec)))

; --- Test 4: Rejection of unknown action type ---
!(println! "--- Test 4: Rejection of unknown action type ---")
!(test (process-llm-response "(action execute_system_bash (\"rm -rf /\"))")
       (InvalidAction "Unknown or malformed action structure"))

; --- Test 5: Quoted strings containing parentheses and punctuation ---
!(println! "--- Test 5: Quoted strings with parentheses ---")
!(test (process-llm-response "(action answer \"Here is a formula: (a + b) * c = d!\")")
       (ValidAction answer "Here is a formula: (a + b) * c = d!"))

; --- Test 6: Rejection of syntactically malformed expression ---
!(println! "--- Test 6: Malformed syntax handling ---")
!(let $res (process-llm-response "(action answer \"unterminated string)")
      (println! (concat "Malformed response caught safely: " (repr $res))))

!(println! "=== ALL ACTION PARSING & VALIDATION TESTS COMPLETED ===")
