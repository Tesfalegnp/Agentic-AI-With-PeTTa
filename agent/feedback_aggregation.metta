;; =============================================================================
;; STAGE D - MILESTONE 12: Feedback Aggregation & Pattern Detection
;; Module: agent/feedback_aggregation.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import! &self "feedback_store.metta")

;; Calculate aggregation metrics for a category (or 'all')
(= (feedback-aggregate $category)
   (let $raw (aggregate_feedback_in_space &feedback_space $category)
     (case $raw
       ((($tag $cat $tot $p $n $c $exp $inf $sc $dom $contra $thresh)
         (FeedbackAggregation $cat $tot $p $n $c $exp $inf $sc $dom $contra $thresh))
        ($_ (FeedbackAggregationFailed $category))))))

;; Check if a recurring pattern exists for a category
(= (feedback-has-recurring-pattern $category)
   (let $agg (feedback-aggregate $category)
     (case $agg
       (((FeedbackAggregation $cat $tot $p $n $c $exp $inf $sc $dom false true)
         (if (== $dom neutral)
             false
             true))
        ($_ false)))))

;; Get supporting feedback IDs for an evidence direction
(= (feedback-get-supporting-ids $category $polarity)
   (get_supporting_feedback_ids &feedback_space $category $polarity))
