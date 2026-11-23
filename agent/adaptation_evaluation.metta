;; =============================================================================
;; STAGE D - MILESTONE 12: Adaptation Effectiveness Evaluation Engine
;; Module: agent/adaptation_evaluation.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "feedback_store.metta")
!(import! &self "adaptation_types.metta")
!(import! &self "adaptation_registry.metta")

!(bind! &adaptation_eval_space (new-space))

;; Initialize or retrieve evaluation record for a rule
(= (evaluation-get-or-init $rule_id)
   (let $found (collapse (match &adaptation_eval_space
                                (AdaptationEvaluation $rule_id $app $pos $neg $corr $last $st)
                                (AdaptationEvaluation $rule_id $app $pos $neg $corr $last $st)))
     (if (== $found ())
         (let* (($now (get_adaptation_timestamp))
                ($init (AdaptationEvaluation $rule_id 0 0 0 0 $now insufficient_evidence)))
           (progn
             (add-atom &adaptation_eval_space $init)
             $init))
         (car-atom $found))))

;; Record that an adaptation rule was applied to a prompt/execution
(= (evaluation-record-application $rule_id)
   (let $eval (evaluation-get-or-init $rule_id)
     (case $eval
       (((AdaptationEvaluation $rule_id $app $pos $neg $corr $last $st)
         (let* (($now (get_adaptation_timestamp))
                ($next_app (+ $app 1))
                ($updated (AdaptationEvaluation $rule_id $next_app $pos $neg $corr $now $st)))
           (progn
             (remove-atom &adaptation_eval_space $eval)
             (add-atom &adaptation_eval_space $updated)
             (EvaluationApplicationRecorded $rule_id $next_app))))))))

;; Evaluate updated status based on feedback counts
(= (compute-eval-status $app $pos $neg $corr)
   (if (and (>= $neg 2) (> $neg $pos))
       review_needed
       (if (and (>= $pos 2) (> $pos $neg))
           effective
           (if (< $app 2)
               insufficient_evidence
               neutral))))

;; Record explicit outcome (feedback) following an application
(= (evaluation-record-outcome $rule_id $polarity)
   (let $eval (evaluation-get-or-init $rule_id)
     (case $eval
       (((AdaptationEvaluation $rule_id $app $pos $neg $corr $last $st)
         (let* (($next_pos  (if (== $polarity positive) (+ $pos 1) $pos))
                ($next_neg  (if (== $polarity negative) (+ $neg 1) $neg))
                ($next_corr (if (== $polarity correction) (+ $corr 1) $corr))
                ($next_st   (compute-eval-status $app $next_pos $next_neg $next_corr))
                ($updated   (AdaptationEvaluation $rule_id $app $next_pos $next_neg $next_corr $last $next_st)))
           (progn
             (remove-atom &adaptation_eval_space $eval)
             (add-atom &adaptation_eval_space $updated)
             (EvaluationOutcomeRecorded $rule_id $polarity $next_st))))))))

;; Retrieve evaluation for rule
(= (evaluation-get $rule_id)
   (let $found (collapse (match &adaptation_eval_space
                                (AdaptationEvaluation $rule_id $app $pos $neg $corr $last $st)
                                (AdaptationEvaluation $rule_id $app $pos $neg $corr $last $st)))
     (if (== $found ())
         (EvaluationNotFound $rule_id)
         (car-atom $found))))

;; Check if a rule requires review/suspension due to repeated negative feedback
(= (evaluation-should-review $rule_id)
   (let $eval (evaluation-get $rule_id)
     (case $eval
       (((AdaptationEvaluation $rule_id $app $pos $neg $corr $last review_needed) true)
        ($_ false)))))

;; Clear evaluation space
(= (evaluation-clear)
   (progn
     (collapse (match &adaptation_eval_space $x (remove-atom &adaptation_eval_space $x)))
     "Evaluation space cleared."))
