;; =============================================================================
;; STAGE C - MILESTONE 7: Tool Argument Validator
;; Module: agent/tool_validator.metta
;; =============================================================================

!(import! &self "tool_registry.metta")

;; Validates a tool invocation:
;; (validate-tool-call tool_name arguments_list)
;; Returns:
;;   (ToolValidationSuccess $tool_name $args)
;;   (ToolValidationFailure $tool_name $reason_message)

(= (validate-tool-call $tool $args)
   (if (not (is-tool-registered $tool))
       (ToolValidationFailure $tool "Unregistered tool name.")
       (if (not (is-tool-enabled $tool))
           (ToolValidationFailure $tool "Tool is currently disabled.")
           (case $tool
             ((calculator
               (case $args
                 ((($expr) (ToolValidationSuccess calculator $args))
                  ($_ (ToolValidationFailure calculator "Calculator requires exactly 1 expression argument.")))))

              (word_counter
               (case $args
                 ((($text) (ToolValidationSuccess word_counter $args))
                  ($_ (ToolValidationFailure word_counter "Word counter requires exactly 1 text argument.")))))

              (text_analyzer
               (case $args
                 ((($text) (ToolValidationSuccess text_analyzer $args))
                  ($_ (ToolValidationFailure text_analyzer "Text analyzer requires exactly 1 text argument.")))))

              (string_reverser
               (case $args
                 ((($text) (ToolValidationSuccess string_reverser $args))
                  ($_ (ToolValidationFailure string_reverser "String reverser requires exactly 1 string argument.")))))

              (datetime
               (case $args
                 ((() (ToolValidationSuccess datetime ()))
                  (($opt) (ToolValidationSuccess datetime ()))
                  ($_ (ToolValidationFailure datetime "DateTime takes at most 1 optional argument.")))))

              (read_file
               (case $args
                 ((($path) (ToolValidationSuccess read_file $args))
                  ($_ (ToolValidationFailure read_file "read_file requires exactly 1 file_path argument.")))))

              (write_file
               (case $args
                 ((($path $content) (ToolValidationSuccess write_file $args))
                  ($_ (ToolValidationFailure write_file "write_file requires exactly 2 arguments: file_path and content.")))))

              (run_command
               (case $args
                 ((($cmd) (ToolValidationSuccess run_command $args))
                  (($cmd $timeout) (ToolValidationSuccess run_command $args))
                  (($cmd $timeout $appr) (ToolValidationSuccess run_command $args))
                  ($_ (ToolValidationFailure run_command "run_command requires command string and optional timeout/approval flags.")))))

              (send_message
               (case $args
                 ((($msg) (ToolValidationSuccess send_message $args))
                  ($_ (ToolValidationFailure send_message "send_message requires exactly 1 message argument.")))))

              (web_search
               (case $args
                 ((($q) (ToolValidationSuccess web_search $args))
                  (($q $n) (ToolValidationSuccess web_search $args))
                  ($_ (ToolValidationFailure web_search "web_search requires a query string and optional max_results count.")))))

              ($_ (ToolValidationFailure $tool "No validation rule for registered tool.")))))))
