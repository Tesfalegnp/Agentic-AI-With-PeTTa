;; =============================================================================
;; STAGE C - MILESTONE 9: Canonical Action Validator
;; Module: agent/action_validator.metta
;; =============================================================================

;; Validates a parsed S-expression against the 8-action canonical protocol.
;; Supports in Milestone 9:
;;   - (action answer "content")
;;   - (action ask_user "question")
;;   - (action finish "summary")
;;   - (action error "diagnostics")
;;   - (action use_tool <tool> (<args>))    -> (ValidAction use_tool <tool> <args>)
;;   - (action use_skill <skill> (<args>))  -> (ValidAction use_skill <skill> <args>)
;;   - (action remember <category> <content>) -> (ValidAction remember <category> <content>)
;;   - (action recall <category> <query>)    -> (ValidAction recall <category> <query>)
;; Rejects all malformed, unregistered, or arbitrary expressions:
;;   - (InvalidAction ...)

(= (validate-action $expr)
   (case $expr
     (((action answer $text)
       (ValidAction answer $text))

      ((action ask_user $question)
       (ValidAction ask_user $question))

      ((action finish $summary)
       (ValidAction finish $summary))

      ((action error $diagnostic)
       (ValidAction error $diagnostic))

      ((action use_tool $tool $args)
       (ValidAction use_tool $tool $args))

      ((action use_skill $skill $args)
       (ValidAction use_skill $skill $args))

      ((action remember $category $content)
       (ValidAction remember $category $content))

      ((action recall $category $query)
       (ValidAction recall $category $query))

      ($_ (InvalidAction "Unrecognized action structure or non-conforming protocol syntax.")))))

;; Full parse-and-validate pipeline
(= (parse-and-validate-response $raw_content)
   (let $parse_result (parse-llm-response $raw_content)
     (case $parse_result
       (((ParseError $err) (ActionError (MalformedResponse $err)))
        ((ParsedSExpr $expr)
         (let $val_result (validate-action $expr)
           (case $val_result
             (((ValidAction $act $payload) (ActionValid $act $payload))
              ((ValidAction use_tool $tool $args) (ActionValid use_tool $tool $args))
              ((ValidAction use_skill $skill $args) (ActionValid use_skill $skill $args))
              ((ValidAction remember $category $content) (ActionValid remember $category $content))
              ((ValidAction recall $category $query) (ActionValid recall $category $query))
              ((UnsupportedCapability $kind $target $reason) (ActionUnsupported $kind $target $reason))
              ((InvalidAction $reason) (ActionError (ValidationFailed $reason)))))))))))
