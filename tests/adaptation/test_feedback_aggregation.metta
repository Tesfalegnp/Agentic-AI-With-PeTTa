;; =============================================================================
;; STAGE D - MILESTONE 12: Unit Test Suite - Feedback Aggregation
;; Test: tests/adaptation/test_feedback_aggregation.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import! &self "../../agent/feedback_aggregation.metta")

!(println! "=== Running Feedback Aggregation Tests ===")

;; Test 1: Repeated independent explicit feedback detection (threshold met)
!(feedback-record verbosity negative answer none "Too long, be concise" "q1" explicit_user 1.0)
!(feedback-record verbosity negative answer none "Please give shorter answers" "q2" explicit_user 1.0)

!(let $agg (feedback-aggregate verbosity)
   (case $agg
     (((FeedbackAggregation verbosity 2 0 2 0 2 0 2.0 negative false true)
       (let $pat (feedback-has-recurring-pattern verbosity)
         (if (== $pat true)
             (println! "Test 1 PASSED: Repeated explicit feedback detected with recurring pattern.")
             (test false true))))
      ($_ (test false true)))))

!(feedback-clear)

;; Test 2: Explicit vs Inferred evidence weighting
!(feedback-record accuracy positive answer none "Accurate calculation" "q1" explicit_user 1.0)
!(feedback-record accuracy positive answer none "Inferred high accuracy" "q2" inferred_signal 0.5)

!(let $agg (feedback-aggregate accuracy)
   (case $agg
     (((FeedbackAggregation accuracy 2 2 0 0 1 1 1.25 positive false false)
       (println! "Test 2 PASSED: Evidence weighted correctly (1.0 vs 0.5), threshold not yet met (score 1.25 < 2.0)."))
      ($_ (test false true)))))

!(feedback-clear)

;; Test 3: Contradictory feedback detection
!(feedback-record verbosity positive answer none "Great detail and length" "q1" explicit_user 1.0)
!(feedback-record verbosity negative answer none "Way too verbose" "q2" explicit_user 1.0)

!(let $agg (feedback-aggregate verbosity)
   (case $agg
     (((FeedbackAggregation verbosity 2 1 1 0 2 0 2.0 mixed true true)
       (let $pat (feedback-has-recurring-pattern verbosity)
         (if (== $pat false)
             (println! "Test 3 PASSED: Contradictory feedback correctly detected and recurring pattern rejected.")
             (test false true))))
      ($_ (test false true)))))

!(feedback-clear)

;; Test 4: Insufficient evidence rejection
!(feedback-record format_preference positive answer none "Like bullet points" "q1" explicit_user 1.0)

!(let $pat (feedback-has-recurring-pattern format_preference)
   (if (== $pat false)
       (println! "Test 4 PASSED: Single feedback event correctly rejected as insufficient evidence.")
       (test false true)))

;; Test 5: Supporting feedback ID retrieval
!(feedback-record format_preference positive answer none "Bullets are clear" "q2" explicit_user 1.0)
!(let $ids (feedback-get-supporting-ids format_preference positive)
   (if (== $ids ("fb_1" "fb_2"))
       (println! "Test 5 PASSED: Supporting feedback IDs retrieved correctly.")
       (test false true)))

;; Reset and cleanup
!(feedback-clear)
!(println! "=== ALL FEEDBACK AGGREGATION TESTS PASSED ===")
