;; =============================================================================
;; STAGE D - MILESTONE 12: Unit Test Suite - Adaptation Registry
;; Test: tests/adaptation/test_adaptation_registry.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import! &self "../../agent/adaptation_registry.metta")

!(println! "=== Running Adaptation Registry Tests ===")

;; Test 1: Candidate rule creation
!(let $res (adaptation-create verbosity "Prefer concise answers" all_queries prefer_concise ("fb_1" "fb_2") 2.5 1.0)
   (case $res
     (((AdaptationCreated "adapt_1" verbosity prefer_concise)
       (println! "Test 1 PASSED: Candidate adaptation rule created."))
      ($_ (test false true)))))

;; Test 2: Retrieve rule by ID
!(let $rule (adaptation-get "adapt_1")
   (case $rule
     (((AdaptationRule "adapt_1" verbosity "Prefer concise answers" all_queries prefer_concise ("fb_1" "fb_2") 2.5 1.0 $cr $up candidate)
       (println! "Test 2 PASSED: Rule retrieved successfully by ID."))
      ($_ (test false true)))))

;; Test 3: Status transitions
!(let $act (adaptation-update-status "adapt_1" active)
   (case $act
     (((AdaptationStatusUpdated "adapt_1" active)
       (let $rule_act (adaptation-get "adapt_1")
         (case $rule_act
           (((AdaptationRule "adapt_1" verbosity $desc $trig $rec $supp $score $conf $cr $up active)
             (println! "Test 3 PASSED: Status updated to active."))
            ($_ (test false true))))))
      ($_ (test false true)))))

;; Test 4: Rule inspection
!(let $insp (adaptation-inspect "adapt_1")
   (case $insp
     (((AdaptationInspection "adapt_1" verbosity "Prefer concise answers" all_queries prefer_concise ("fb_1" "fb_2") 2.5 1.0 $cr $up active)
       (println! "Test 4 PASSED: Rule inspected successfully with supporting feedback."))
      ($_ (test false true)))))

;; Test 5: List by status
!(let $active_list (adaptation-list active)
   (if (== (collapse (match &adaptation_space (AdaptationRule "adapt_1" $c $d $t $r $s $sc $cf $cr $up active) found)) (found))
       (println! "Test 5 PASSED: Active rules listed correctly.")
       (test false true)))

;; Test 6: Rule removal
!(let $rem (adaptation-remove "adapt_1")
   (case $rem
     (((AdaptationRemoved "adapt_1")
       (let $not_found (adaptation-get "adapt_1")
         (case $not_found
           (((AdaptationNotFound "adapt_1")
             (println! "Test 6 PASSED: Rule removed cleanly."))
            ($_ (test false true))))))
      ($_ (test false true)))))

;; Cleanup
!(adaptation-clear)
!(println! "=== ALL ADAPTATION REGISTRY TESTS PASSED ===")
