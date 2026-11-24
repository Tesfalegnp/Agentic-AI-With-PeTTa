;; =============================================================================
;; STAGE C - MILESTONE 7: Tool Execution Dispatcher
;; Module: agent/tool_dispatcher.metta
;; =============================================================================

!(import! &self "tool_registry.metta")
!(import! &self "tool_validator.metta")
!(import! &self "tool_result.metta")
!(import! &self "tool_history.metta")

;; Built-in tool implementations
!(import! &self "../tools/builtin/calculator.metta")
!(import! &self "../tools/builtin/word_counter.metta")
!(import! &self "../tools/builtin/text_analyzer.metta")
!(import! &self "../tools/builtin/string_reverser.metta")
!(import! &self "../tools/builtin/datetime.metta")
!(import! &self "../tools/builtin/read_file.metta")
!(import! &self "../tools/builtin/write_file.metta")
!(import! &self "../tools/builtin/run_command.metta")
!(import! &self "../tools/builtin/send_message.metta")

;; Dispatches a validated tool call to its PeTTa implementation
(= (dispatch-tool-internal $tool $args)
   (case $tool
     ((calculator (run-calculator $args))
      (word_counter (run-word-counter $args))
      (text_analyzer (run-text-analyzer $args))
      (string_reverser (run-string-reverser $args))
      (datetime (run-datetime $args))
      (read_file (run-read-file $args))
      (write_file (run-write-file $args))
      (run_command (run-run-command $args))
      (send_message (run-send-message $args))
      ($_ (make-tool-failure $tool "Unimplemented tool binding.")))))

;; Public Dispatcher Entry Point
;; Validates, dispatches, normalizes result, and records history
(= (dispatch-tool $tool $args)
   (let $val_result (validate-tool-call $tool $args)
     (case $val_result
       (((ToolValidationSuccess $tool $validated_args)
         (let $res (dispatch-tool-internal $tool $validated_args)
           (case $res
             (((ToolResult success $t $val)
               (progn
                 (history-record-tool-call $t $validated_args success (repr $val))
                 (ToolResult success $t $val)))
              ((ToolResult failure $t $err)
               (progn
                 (history-record-tool-call $t $validated_args failure $err)
                 (ToolResult failure $t $err)))
              ($_
               (let $err_res (make-tool-failure $tool "Malformed result returned by tool.")
                 (progn
                   (history-record-tool-call $tool $validated_args failure "Malformed result returned by tool.")
                   $err_res)))))))

        ((ToolValidationFailure $tool $reason)
         (let $err_res (make-tool-failure $tool $reason)
           (progn
             (history-record-tool-call $tool $args failure $reason)
             $err_res)))))))
