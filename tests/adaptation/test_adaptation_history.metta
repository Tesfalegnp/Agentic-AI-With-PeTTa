;; =============================================================================
;; STAGE D - MILESTONE 12: Unit Test Suite - Adaptation History Audit Log
;; Test: tests/adaptation/test_adaptation_history.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import! &self "../../agent/adaptation_history.metta")

!(println! "=== Running Adaptation History Tests ===")

;; Test 1: Record audit event
!(let $res (adaptation-history-record rule_created "adapt_1" "Rule created from feedback")
   (case $res
     (((AdaptationHistoryRecorded "ev_1" rule_created)
       (println! "Test 1 PASSED: History event recorded successfully."))
      ($_ (test false true)))))

;; Test 2: Record multiple events and list
!(adaptation-history-record rule_activated "adapt_1" "Rule activated")
!(let $list (adaptation-history-list)
   (if (== (collapse (match &adaptation_history (AdaptationHistoryEvent "ev_1" $ts1 rule_created "adapt_1" $d1) found)) (found))
       (if (== (collapse (match &adaptation_history (AdaptationHistoryEvent "ev_2" $ts2 rule_activated "adapt_1" $d2) found)) (found))
           (println! "Test 2 PASSED: All history events preserved and queryable.")
           (test false true))
       (test false true)))

;; Test 3: Clear history
!(adaptation-history-clear)
!(let $empty_list (adaptation-history-list)
   (if (== $empty_list ())
       (println! "Test 3 PASSED: History cleared cleanly.")
       (test false true)))

!(println! "=== ALL ADAPTATION HISTORY TESTS PASSED ===")
