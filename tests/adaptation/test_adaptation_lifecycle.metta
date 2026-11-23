;; =============================================================================
;; STAGE D - MILESTONE 12: Unit Test Suite - Adaptation Lifecycle
;; Test: tests/adaptation/test_adaptation_lifecycle.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import! &self "../../agent/adaptation_lifecycle.metta")

!(println! "=== Running Adaptation Lifecycle Tests ===")

;; Test 1: Activation of candidate rule
!(adaptation-create verbosity "Prefer concise answers" all_queries prefer_concise ("fb_1" "fb_2") 2.5 1.0)
!(let $act (adaptation-activate "adapt_1")
   (case $act
     (((AdaptationActivated "adapt_1")
       (println! "Test 1 PASSED: Candidate rule validated and activated."))
      ($_ (test false true)))))

;; Test 2: Suspension of active rule
!(let $susp (adaptation-suspend "adapt_1")
   (case $susp
     (((AdaptationSuspended "adapt_1")
       (println! "Test 2 PASSED: Active rule suspended successfully."))
      ($_ (test false true)))))

;; Test 3: Restoration of suspended rule
!(let $rest (adaptation-restore "adapt_1")
   (case $rest
     (((AdaptationStatusUpdated "adapt_1" active)
       (println! "Test 3 PASSED: Suspended rule restored to active."))
      ($_ (test false true)))))

;; Test 4: Disabling of active rule
!(let $dis (adaptation-disable "adapt_1")
   (case $dis
     (((AdaptationDisabled "adapt_1")
       (println! "Test 4 PASSED: Active rule disabled successfully."))
      ($_ (test false true)))))

;; Test 5: Supersede rule with new rule
!(adaptation-update-status "adapt_1" active)
!(adaptation-create format_preference "Prefer bullet points" all_queries prefer_bullet_format ("fb_3" "fb_4") 2.5 1.0)
!(let $sup (adaptation-supersede "adapt_1" "adapt_2")
   (case $sup
     (((AdaptationSuperseded "adapt_1" "adapt_2")
       (let $r1 (adaptation-get "adapt_1")
         (let $r2 (adaptation-get "adapt_2")
           (case ($r1 $r2)
             ((((AdaptationRule "adapt_1" $c1 $d1 $t1 $rec1 $s1 $sc1 $cf1 $cr1 $up1 superseded)
                (AdaptationRule "adapt_2" $c2 $d2 $t2 $rec2 $s2 $sc2 $cf2 $cr2 $up2 active))
               (println! "Test 5 PASSED: Old rule superseded and new rule activated."))
              ($_ (test false true)))))))
      ($_ (test false true)))))

;; Cleanup
!(adaptation-clear)
!(println! "=== ALL ADAPTATION LIFECYCLE TESTS PASSED ===")
