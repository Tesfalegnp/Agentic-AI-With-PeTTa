;; =============================================================================
;; Built-in Tool: read_file
;; Module: tools/builtin/read_file.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_functions_from_file "tools/system_primitives.pl" (
    read_file_safe
))

!(import! &self "../../agent/tool_result.metta")

(= (run-read-file $args)
   (case $args
     ((($path)
       (let $res (read_file_safe $path)
         (case $res
           (((success $content) (make-tool-success read_file $content))
            ((failure $err)     (make-tool-failure read_file $err))
            ($_                 (make-tool-failure read_file "Malformed response from read_file."))))))
      ($_ (make-tool-failure read_file "read_file requires exactly 1 argument: file_path.")))))
