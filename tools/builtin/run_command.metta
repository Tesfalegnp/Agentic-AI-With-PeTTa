;; =============================================================================
;; Built-in Tool: run_command
;; Module: tools/builtin/run_command.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_functions_from_file "tools/system_primitives.pl" (
    execute_shell_command_safe
))

!(import! &self "../../agent/tool_result.metta")

(= (run-run-command $args)
   (case $args
     ((($cmd $timeout $approved)
       (let $res (execute_shell_command_safe $cmd $timeout $approved)
         (case $res
           (((success $out) (make-tool-success run_command $out))
            ((failure $err) (make-tool-failure run_command $err))
            ($_             (make-tool-failure run_command "Malformed response from run_command."))))))
      (($cmd $timeout)
       (run-run-command ($cmd $timeout false)))
      (($cmd)
       (run-run-command ($cmd 10 false)))
      ($_ (make-tool-failure run_command "run_command requires command string, optional timeout (seconds), and optional approved flag.")))))
