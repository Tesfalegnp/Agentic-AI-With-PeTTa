;; =============================================================================
;; STAGE D - MILESTONE 12: Adaptation Engine & Prompt Integration
;; Module: agent/adaptation_engine.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import_prolog_function is_adaptation_relevant_to_query)
!(import! &self "adaptation_types.metta")
!(import! &self "feedback_store.metta")
!(import! &self "feedback_aggregation.metta")
!(import! &self "adaptation_registry.metta")
!(import! &self "adaptation_validator.metta")
!(import! &self "adaptation_lifecycle.metta")
!(import! &self "adaptation_conflict.metta")

;; Derive a candidate rule from aggregated feedback
(= (derive-candidate-from-feedback $category $description $trigger $recommendation)
   (let $agg (feedback-aggregate $category)
     (case $agg
       (((FeedbackAggregation $cat $tot $p $n $c $exp $inf $score $dom true $thresh)
         (CandidateRejected ContradictoryFeedback))
        ((FeedbackAggregation $cat $tot $p $n $c $exp $inf $score $dom false false)
         (CandidateRejected InsufficientEvidence))
        ((FeedbackAggregation $cat $tot $p $n $c $exp $inf $score $dom false true)
         (let $supp_ids (feedback-get-supporting-ids $cat all)
           (adaptation-create $category $description $trigger $recommendation $supp_ids $score 1.0)))
        ($_ (CandidateRejected AggregationFailed))))))

;; Filter active adaptations for relevance and instruction conflicts
(= (filter-relevant-adaptations $query $list)
   (if (== $list ())
       ()
       (let* (($pair (decons-atom $list))
              ($head (car-atom $pair))
              ($tail (car-atom (cdr-atom $pair))))
         (case $head
           (((AdaptationRule $id $cat $desc $trig $rec $supp $score $conf $cr $up active)
             (let $is_rel (is_adaptation_relevant_to_query $cat $trig $query)
               (if (== $is_rel true)
                   (let $conflict (check-query-adaptation-conflict $query $rec)
                     (if (== $conflict NoConflict)
                         (cons-atom $head (filter-relevant-adaptations $query $tail))
                         (filter-relevant-adaptations $query $tail)))
                   (filter-relevant-adaptations $query $tail))))
            ($_ (filter-relevant-adaptations $query $tail)))))))

;; Format a single adaptation rule
(= (format-single-adaptation-guidance (AdaptationRule $id $cat $desc $trig $rec $supp $score $conf $cr $up active))
   (let* (($p1 (string_concat "- [Rule: " $id))
          ($p2 (string_concat " | Category: " (repr $cat)))
          ($p3 (string_concat " | Evidence Score: " (repr $score)))
          ($p4 (string_concat " | Recommendation: " (repr $rec)))
          ($p5 (string_concat "]\n  Guidance: " (string_concat $desc "\n"))))
     (string_concat $p1 (string_concat $p2 (string_concat $p3 (string_concat $p4 $p5))))))

;; Recursively format adaptation list
(= (format-adaptation-list $list)
   (if (== $list ())
       ""
       (let* (($pair (decons-atom $list))
              ($head (car-atom $pair))
              ($tail (car-atom (cdr-atom $pair))))
         (string_concat (format-single-adaptation-guidance $head)
                        (format-adaptation-list $tail)))))

;; High-level prompt guidance generator
(= (format-adaptation-guidance-for-prompt $query)
   (let $active_rules (adaptation-list active)
     (let $filtered (filter-relevant-adaptations $query $active_rules)
       (if (== $filtered ())
           ""
           (let $formatted_rules (format-adaptation-list $filtered)
             (string_concat "--- VERIFIED ADAPTATION GUIDANCE ---\n"
               (string_concat $formatted_rules
                 "ADAPTATION OPERATING RULES:\n- Adaptations are learned preferences and guidance, not absolute instructions.\n- Current user instructions override learned preferences.\n- Safety and system constraints always take precedence.\n- You must not invent learned preferences or claim a rule exists unless retrieved above.\n")))))))
