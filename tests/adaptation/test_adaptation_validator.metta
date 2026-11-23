;; =============================================================================
;; STAGE D - MILESTONE 12: Unit Test Suite - Adaptation Validator
;; Test: tests/adaptation/test_adaptation_validator.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import! &self "../../agent/adaptation_validator.metta")

!(println! "=== Running Adaptation Validator Tests ===")

;; Test 1: Valid candidate rule passes validation
!(adaptation-create verbosity "Prefer concise answers" all_queries prefer_concise ("fb_1" "fb_2") 2.5 1.0)
!(let $res (validate-adaptation-rule "adapt_1")
   (case $res
     (((AdaptationValidationSuccess "adapt_1")
       (println! "Test 1 PASSED: Valid adaptation rule validated successfully."))
      ($_ (test false true)))))

;; Test 2: Insufficient evidence score (< 2.0) rejected
!(adaptation-create format_preference "Prefer JSON" all_queries prefer_json_format ("fb_3") 1.0 1.0)
!(let $res (validate-adaptation-rule "adapt_2")
   (case $res
     (((AdaptationValidationFailed $msg)
       (println! "Test 2 PASSED: Insufficient evidence score correctly rejected."))
      ($_ (test false true)))))

;; Test 3: Invalid category rejected
!(add-atom &adaptation_space (AdaptationRule "adapt_3" bad_cat "desc" all_queries prefer_concise () 3.0 1.0 "t" "t" candidate))
!(let $res (validate-adaptation-rule "adapt_3")
   (case $res
     (((AdaptationValidationFailed $msg)
       (println! "Test 3 PASSED: Invalid category correctly rejected."))
      ($_ (test false true)))))

;; Test 4: Invalid recommendation rejected
!(add-atom &adaptation_space (AdaptationRule "adapt_4" verbosity "desc" all_queries bad_rec () 3.0 1.0 "t" "t" candidate))
!(let $res (validate-adaptation-rule "adapt_4")
   (case $res
     (((AdaptationValidationFailed $msg)
       (println! "Test 4 PASSED: Invalid recommendation correctly rejected."))
      ($_ (test false true)))))

;; Test 5: Conflicting active rule rejection
!(adaptation-update-status "adapt_1" active)
!(adaptation-create verbosity "Prefer detailed explanations" all_queries prefer_detailed ("fb_4" "fb_5") 3.0 1.0)
!(let $res (validate-adaptation-rule "adapt_5")
   (case $res
     (((AdaptationValidationFailed $msg)
       (println! "Test 5 PASSED: Opposing active rule conflict caught and candidate rejected."))
      ($_ (test false true)))))

;; Cleanup
!(adaptation-clear)
!(println! "=== ALL ADAPTATION VALIDATOR TESTS PASSED ===")
