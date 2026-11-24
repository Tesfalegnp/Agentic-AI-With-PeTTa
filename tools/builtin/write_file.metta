;; =============================================================================
;; Built-in Tool: write_file
;; Module: tools/builtin/write_file.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_functions_from_file "tools/system_primitives.pl" (
    write_file_safe
))

!(import! &self "../../agent/tool_result.metta")

(= (run-write-file $args)
   (case $args
     ((($path $content)
       (let $res (write_file_safe $path $content)
         (case $res
           (((success $status) (make-tool-success write_file $status))
            ((failure $err)    (make-tool-failure write_file $err))
            ($_                (make-tool-failure write_file "Malformed response from write_file."))))))
      ($_ (make-tool-failure write_file "write_file requires exactly 2 arguments: file_path and content.")))))
