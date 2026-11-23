;; =============================================================================
;; STAGE C - MILESTONE 7: Word Counter Built-in Tool
;; Module: tools/builtin/word_counter.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_functions_from_file "tools/tool_primitives.pl" (count_words))
!(import! &self "../../agent/tool_result.metta")

(= (run-word-counter $args)
   (case $args
     ((($text)
       (let $cnt (count_words $text)
         (make-tool-success word_counter $cnt)))
      ($_ (make-tool-failure word_counter "Invalid argument format. Expected 1 text string.")))))
