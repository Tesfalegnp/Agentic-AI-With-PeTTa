;; =============================================================================
;; STAGE D - MILESTONE 12: Unit Test Suite - Adaptation Disk Persistence
;; Test: tests/adaptation/test_adaptation_persistence.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import! &self "../../agent/adaptation_persistence.metta")

!(println! "=== Running Adaptation Persistence Tests ===")

;; Test 1: Populate spaces and save to disk
!(feedback-record verbosity negative answer none "Too verbose" "q1" explicit_user 1.0)
!(adaptation-create verbosity "Prefer concise answers" all_queries prefer_concise ("fb_1") 2.5 1.0)
!(adaptation-history-record rule_created "adapt_1" "Rule created for verbosity")
!(evaluation-record-application "adapt_1")

!(let $save (adaptation-save-to-disk)
   (case $save
     (((AdaptationSaveSuccess (feedback 1) (adaptations 1) (history 1) (evals 1))
       (println! "Test 1 PASSED: All 4 adaptation spaces saved to disk."))
      ($_ (test false true)))))

;; Test 2: Clear in-memory spaces
!(feedback-clear)
!(adaptation-clear)
!(adaptation-history-clear)
!(evaluation-clear)

!(if (== (feedback-list all) ())
     (if (== (adaptation-list all) ())
         (if (== (adaptation-history-list) ())
             (println! "Test 2 PASSED: In-memory spaces cleared.")
             (test false true))
         (test false true))
     (test false true))

;; Test 3: Load records from disk and verify restored records
!(let $load (adaptation-load-from-disk)
   (case $load
     (((AdaptationLoadSuccess (feedback 1) (adaptations 1) (history 1) (evals 1))
       (let $fb (feedback-get "fb_1")
         (let $ad (adaptation-get "adapt_1")
           (let $ev (evaluation-get "adapt_1")
             (case ($fb $ad $ev)
               ((((FeedbackRecord "fb_1" verbosity negative answer none "Too verbose" "q1" explicit_user 1.0 $ts1 active)
                  (AdaptationRule "adapt_1" verbosity "Prefer concise answers" all_queries prefer_concise ("fb_1") 2.5 1.0 $cr $up candidate)
                  (AdaptationEvaluation "adapt_1" 1 0 0 0 $ts2 insufficient_evidence))
                 (println! "Test 3 PASSED: All records restored correctly from disk."))
                ($_ (test false true))))))))
      ($_ (test false true)))))

;; Test 4: Clear disk storage
!(let $clr (adaptation-clear-disk)
   (if (== $clr "Adaptation disk storage cleared.")
       (println! "Test 4 PASSED: Disk storage cleared cleanly.")
       (test false true)))

;; Cleanup in-memory spaces
!(feedback-clear)
!(adaptation-clear)
!(adaptation-history-clear)
!(evaluation-clear)

!(println! "=== ALL ADAPTATION PERSISTENCE TESTS PASSED ===")
