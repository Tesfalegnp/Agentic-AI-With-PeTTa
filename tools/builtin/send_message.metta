;; =============================================================================
;; Built-in Tool: send_message
;; Module: tools/builtin/send_message.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_functions_from_file "tools/system_primitives.pl" (
    send_user_message_safe
))

!(import! &self "../../agent/tool_result.metta")

(= (run-send-message $args)
   (case $args
     ((($msg)
       (let $res (send_user_message_safe $msg)
         (case $res
           (((success $out) (make-tool-success send_message $out))
            ((failure $err) (make-tool-failure send_message $err))
            ($_             (make-tool-failure send_message "Malformed response from send_message."))))))
      ($_ (make-tool-failure send_message "send_message requires exactly 1 argument: message text.")))))
