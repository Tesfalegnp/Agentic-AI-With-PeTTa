;; =============================================================================
;; STAGE C - MILESTONE 7: String Reverser Built-in Tool
;; Module: tools/builtin/string_reverser.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_functions_from_file "tools/tool_primitives.pl" (reverse_string))
!(import! &self "../../agent/tool_result.metta")

(= (run-string-reverser $args)
   (case $args
     ((($text)
       (let $rev (reverse_string $text)
         (make-tool-success string_reverser $rev)))
      ($_ (make-tool-failure string_reverser "Invalid argument format. Expected 1 string argument.")))))
