;; =============================================================================
;; STAGE C - MILESTONE 7: DateTime Built-in Tool
;; Module: tools/builtin/datetime.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_functions_from_file "tools/tool_primitives.pl" (get_current_datetime_str))
!(import! &self "../../agent/tool_result.metta")

(= (run-datetime $args)
   (let $dt (get_current_datetime_str)
     (make-tool-success datetime $dt)))
