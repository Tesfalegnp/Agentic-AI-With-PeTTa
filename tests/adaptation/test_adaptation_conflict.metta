;; =============================================================================
;; STAGE D - MILESTONE 12: Unit Test Suite - Adaptation Conflict Detection
;; Test: tests/adaptation/test_adaptation_conflict.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import! &self "../../agent/adaptation_conflict.metta")

!(println! "=== Running Adaptation Conflict Detection Tests ===")

;; Test 1: Query explicitly requests detail vs prefer_concise rule
!(let $res (check-query-adaptation-conflict "Explain in detail the theory of relativity" prefer_concise)
   (case $res
     (((InstructionConflict $msg)
       (println! "Test 1 PASSED: Detail instruction conflict caught for prefer_concise."))
      ($_ (test false true)))))

;; Test 2: Query explicitly requests brevity vs prefer_detailed rule
!(let $res (check-query-adaptation-conflict "Give a brief, short summary" prefer_detailed)
   (case $res
     (((InstructionConflict $msg)
       (println! "Test 2 PASSED: Brevity instruction conflict caught for prefer_detailed."))
      ($_ (test false true)))))

;; Test 3: Query explicitly requests table vs avoid_markdown_table rule
!(let $res (check-query-adaptation-conflict "Show the data in a table" avoid_markdown_table)
   (case $res
     (((InstructionConflict $msg)
       (println! "Test 3 PASSED: Table instruction conflict caught for avoid_markdown_table."))
      ($_ (test false true)))))

;; Test 4: Neutral query produces NoConflict
!(let $res (check-query-adaptation-conflict "What is the capital of Japan?" prefer_concise)
   (if (== $res NoConflict)
       (println! "Test 4 PASSED: Neutral query correctly produces NoConflict.")
       (test false true)))

;; Test 5: Conflict detection between opposing active rules in space
!(adaptation-create verbosity "Concise" all_queries prefer_concise () 2.5 1.0)
!(adaptation-create verbosity "Detailed" all_queries prefer_detailed () 2.5 1.0)
!(adaptation-update-status "adapt_1" active)
!(adaptation-update-status "adapt_2" active)

!(let $conflicts (detect-internal-adaptation-conflicts)
   (if (== (collapse (match &adaptation_space (AdaptationRule "adapt_1" verbosity $d1 $t1 prefer_concise $s1 $sc1 $c1 $cr1 $u1 active) found)) (found))
       (println! "Test 5 PASSED: Internal opposing rules detected in space.")
       (test false true)))

;; Cleanup
!(adaptation-clear)
!(println! "=== ALL ADAPTATION CONFLICT TESTS PASSED ===")
