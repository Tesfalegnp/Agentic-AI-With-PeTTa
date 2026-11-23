;; =============================================================================
;; STAGE D - MILESTONE 12: Adaptation Rule Validator
;; Module: agent/adaptation_validator.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import_prolog_function detect_adaptation_rule_conflicts_in_space)
!(import! &self "adaptation_types.metta")
!(import! &self "adaptation_registry.metta")

;; Check if a candidate rule conflicts with currently active rules
(= (check-rule-conflicts $rule_id $cat $rec)
   (let $active_rules (adaptation-list active)
     (check-opposing-active-rules $rule_id $cat $rec $active_rules)))

(= (check-opposing-active-rules $rule_id $cat $rec ()) no_conflict)
(= (check-opposing-active-rules $rule_id $cat $rec ($head $tail))
   (case $head
     (((AdaptationRule $other_id $other_cat $d $t $other_rec $s $sc $cf $cr $up active)
       (if (== $cat $other_cat)
           (case ($rec $other_rec)
             (((prefer_concise prefer_detailed) (RuleConflictDetected $other_id))
              ((prefer_detailed prefer_concise) (RuleConflictDetected $other_id))
              ((include_calculations omit_calculations) (RuleConflictDetected $other_id))
              ((omit_calculations include_calculations) (RuleConflictDetected $other_id))
              ((prefer_bullet_format prefer_plain_text) (RuleConflictDetected $other_id))
              ((prefer_plain_text prefer_bullet_format) (RuleConflictDetected $other_id))
              ((prefer_tool_execution prefer_skill_execution) (RuleConflictDetected $other_id))
              ((prefer_skill_execution prefer_tool_execution) (RuleConflictDetected $other_id))
              ($_ (check-opposing-active-rules $rule_id $cat $rec $tail))))
           (check-opposing-active-rules $rule_id $cat $rec $tail)))
      ($_ (check-opposing-active-rules $rule_id $cat $rec $tail)))))

;; Validate a candidate adaptation rule
(= (validate-adaptation-rule $rule_id)
   (let $found (adaptation-get $rule_id)
     (case $found
       (((AdaptationRule $id $cat $desc $trig $rec $supp $score $conf $cr $up $st)
         (if (== (is-valid-adaptation-category $cat) false)
             (AdaptationValidationFailed (string_concat "Invalid adaptation category: " (repr $cat)))
             (if (== (is-valid-adaptation-recommendation $rec) false)
                 (AdaptationValidationFailed (string_concat "Invalid adaptation recommendation: " (repr $rec)))
                 (if (== (is_valid_confidence_val $conf) false)
                     (AdaptationValidationFailed (string_concat "Invalid confidence: " (repr $conf)))
                     (if (< $score 2.0)
                         (AdaptationValidationFailed (string_concat "Insufficient evidence score: " (repr $score)))
                         (let $conflict (check-rule-conflicts $id $cat $rec)
                           (case $conflict
                             (((RuleConflictDetected $other_id)
                               (AdaptationValidationFailed (string_concat "Conflicting active rule exists: " $other_id)))
                              (no_conflict
                               (AdaptationValidationSuccess $id))))))))))
        ($_ (AdaptationValidationFailed (string_concat "Rule not found: " $rule_id)))))))
