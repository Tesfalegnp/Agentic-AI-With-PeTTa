;; =============================================================================
;; STAGE C - MILESTONE 7: Calculator Built-in Tool
;; Module: tools/builtin/calculator.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_functions_from_file "tools/tool_primitives.pl" (eval_math_expression))
!(import! &self "../../agent/tool_result.metta")

(= (run-calculator $args)
   (case $args
     ((($expr)
       (let $res (eval_math_expression $expr)
         (if (== $res "error: division by zero")
             (make-tool-failure calculator "Division by zero error.")
             (if (== $res "error: malformed or unsupported mathematical expression")
                 (make-tool-failure calculator "Malformed or unsupported mathematical expression.")
                 (make-tool-success calculator $res)))))
      ($_ (make-tool-failure calculator "Invalid argument format. Expected 1 expression string.")))))
