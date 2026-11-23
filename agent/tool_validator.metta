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

              ($_ (ToolValidationFailure $tool "No validation rule for registered tool.")))))))
