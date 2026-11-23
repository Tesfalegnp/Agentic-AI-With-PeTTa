;; =============================================================================
;; STAGE D - MILESTONE 12: Unit Test Suite - Adaptation Effectiveness Evaluation
;; Test: tests/adaptation/test_adaptation_evaluation.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import! &self "../../agent/adaptation_evaluation.metta")

!(println! "=== Running Adaptation Evaluation Tests ===")

;; Test 1: Record application increments count
!(let $res (evaluation-record-application "adapt_1")
   (case $res
     (((EvaluationApplicationRecorded "adapt_1" 1)
       (let $ev (evaluation-get "adapt_1")
         (case $ev
           (((AdaptationEvaluation "adapt_1" 1 0 0 0 $last insufficient_evidence)
             (println! "Test 1 PASSED: Application count incremented to 1."))
            ($_ (test false true))))))
      ($_ (test false true)))))

;; Test 2: Explicit positive outcome transitions toward effective
!(evaluation-record-application "adapt_1")
!(let $out1 (evaluation-record-outcome "adapt_1" positive)
   (let $out2 (evaluation-record-outcome "adapt_1" positive)
     (case $out2
       (((EvaluationOutcomeRecorded "adapt_1" positive effective)
         (let $ev (evaluation-get "adapt_1")
           (case $ev
             (((AdaptationEvaluation "adapt_1" 2 2 0 0 $last effective)
               (println! "Test 2 PASSED: 2 positive outcomes transitioned evaluation to effective."))
              ($_ (test false true))))))
        ($_ (test false true))))))

;; Test 3: Explicit negative outcome triggers review_needed
!(evaluation-record-application "adapt_2")
!(evaluation-record-application "adapt_2")
!(evaluation-record-outcome "adapt_2" negative)
!(let $out_neg2 (evaluation-record-outcome "adapt_2" negative)
   (case $out_neg2
     (((EvaluationOutcomeRecorded "adapt_2" negative review_needed)
       (let $rev (evaluation-should-review "adapt_2")
         (if (== $rev true)
             (println! "Test 3 PASSED: Repeated negative feedback triggers review_needed status.")
             (test false true))))
      ($_ (test false true)))))

;; Test 4: Missing feedback does not increment positive or negative count
!(evaluation-record-application "adapt_3")
!(let $ev3 (evaluation-get "adapt_3")
   (case $ev3
     (((AdaptationEvaluation "adapt_3" 1 0 0 0 $last insufficient_evidence)
       (println! "Test 4 PASSED: Unassisted application preserves zero outcome counts (silence is not success)."))
      ($_ (test false true)))))

;; Test 5: Single negative outcome does not delete or prematurely trigger review_needed
!(evaluation-record-application "adapt_4")
!(evaluation-record-application "adapt_4")
!(let $out_neg1 (evaluation-record-outcome "adapt_4" negative)
   (let $rev4 (evaluation-should-review "adapt_4")
     (if (== $rev4 false)
         (println! "Test 5 PASSED: Single negative outcome does not prematurely trigger review_needed.")
         (test false true))))

;; Cleanup
!(evaluation-clear)
!(println! "=== ALL ADAPTATION EVALUATION TESTS PASSED ===")
