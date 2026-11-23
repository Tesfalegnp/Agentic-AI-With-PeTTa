;; =============================================================================
;; STAGE C - MILESTONE 6: LLM Response Parser
;; Module: agent/response_parser.metta
;; =============================================================================

;; Import Prolog string extraction helper
!(import! &self (library lib_import))
!(import_prolog_functions_from_file "agent/parser_helper.pl" (clean_action_string))

;; Safe sread with error trapping
(= (safe-sread $str)
   (case (catch (sread $str))
     (((Error $type $msg) (ParseError (syntax_error $msg)))
      ($valid $valid))))

;; Parse raw LLM output string into canonical PeTTa S-expression
(= (parse-llm-response $raw_content)
   (if (== $raw_content "")
       (ParseError (empty_response "LLM returned an empty content string."))
       (let* (($cleaned (clean_action_string $raw_content))
              ($parsed  (safe-sread $cleaned)))
         (case $parsed
           (((ParseError $err) (ParseError $err))
            ($expr (ParsedSExpr $expr)))))))
