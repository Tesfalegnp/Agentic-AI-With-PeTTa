;; =============================================================================
;; STAGE C - MILESTONE 7: Text Analyzer Built-in Tool
;; Module: tools/builtin/text_analyzer.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_functions_from_file "tools/tool_primitives.pl" (analyze_text))
!(import! &self "../../agent/tool_result.metta")

(= (run-text-analyzer $args)
   (case $args
     ((($text)
       (let (text_stats $chars $words $lines $sentences) (analyze_text $text)
         (make-tool-success text_analyzer
           (TextAnalysis $chars $words $lines $sentences))))
      ($_ (make-tool-failure text_analyzer "Invalid argument format. Expected 1 text string.")))))
