;; =============================================================================
;; STAGE D - MILESTONE 10: Memory Consistency & Staleness Manager Unit Tests
;; File: tests/memory/test_memory_consistency.metta
;; =============================================================================

!(println! "=== Starting Memory Consistency & Staleness Tests ===")

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "../../agent/memory_store.metta")
!(import! &self "../../agent/memory_core.metta")
!(import! &self "../../agent/memory_consistency.metta")

;; Initialize clean memory state
!(memory-reset-all)

;; Test 1: Clean consistency check on empty / harmonious memory
!(println! "--- Test 1: Consistency on Clean Memory ---")
!(let $res1 (memory-check-internal-conflicts)
   (case $res1
     (((ConsistencyCheckPassed $msg) (println! "Test 1 PASSED: Clean consistency passed as expected."))
      ($_ (test "expected ConsistencyCheckPassed" "got conflict unexpectedly")))))

;; Test 2: Add single preference and verify consistency still passes
!(println! "--- Test 2: Single Active Preference ---")
!(memory-store preference "User prefers concise answers.")
!(let $res2 (memory-check-internal-conflicts)
   (case $res2
     (((ConsistencyCheckPassed $msg) (println! "Test 2 PASSED: Single preference is consistent."))
      ($_ (test "expected ConsistencyCheckPassed" "failed")))))

;; Test 3: Add conflicting preference and detect contradiction
!(println! "--- Test 3: Detecting Contradictory Preferences ---")
!(memory-store preference "User prefers detailed and verbose answers.")
!(let $res3 (memory-check-internal-conflicts)
   (case $res3
     (((ConsistencyConflictDetected $items)
       (let $_t (test (> (length $items) 0) True)
         (println! "Test 3 PASSED: Detected preference conflict pair.")))
      ($_ (test "expected ConsistencyConflictDetected" "none detected")))))

;; Test 4: Statement conflict detection
!(println! "--- Test 4: Statement Conflict Detection ---")
;; Test conflicting statement
!(let $s_conf (memory-check-statement-conflict "Please give me a concise response.")
   (case $s_conf
     (((StatementConflictDetected $items)
       (let $_t (test (> (length $items) 0) True)
         (println! "Test 4a PASSED: Statement conflict correctly detected against verbose preference.")))
      ($_ (test "expected StatementConflictDetected" "none detected")))))

;; Test non-conflicting statement
!(let $s_clean (memory-check-statement-conflict "The sky is blue today.")
   (case $s_clean
     (((StatementConsistent $st)
       (println! "Test 4b PASSED: Harmonious statement detected as consistent."))
      ($_ (test "expected StatementConsistent" "got conflict")))))

;; Test 5: Record staleness check
!(println! "--- Test 5: Staleness Threshold Verification ---")
;; Fresh check (large threshold like 100,000 seconds)
!(let $fresh_check (check-record-staleness "mem_1" 100000)
   (case $fresh_check
     (((RecordFresh "mem_1" $age)
       (println! "Test 5a PASSED: Newly created record is fresh."))
      ($_ (test "expected RecordFresh" "got stale or error")))))

;; Stale check (threshold 0 seconds: age >= 0 will be stale)
!(let $stale_check (check-record-staleness "mem_1" 0)
   (case $stale_check
     (((RecordStale "mem_1" $age)
       (println! "Test 5b PASSED: Record exceeding threshold is classified as stale."))
      ($_ (test "expected RecordStale" "got fresh")))))

;; Non-existent record check
!(let $missing_check (check-record-staleness "mem_nonexistent" 100000)
   (case $missing_check
     (((StalenessCheckError $err)
       (println! "Test 5c PASSED: Non-existent record correctly triggers StalenessCheckError."))
      ($_ (test "expected StalenessCheckError" "got other")))))

;; Test 6: Consistency guidance formatting
!(println! "--- Test 6: Consistency Guidance String Formatting ---")
!(let $g_passed (format-consistency-guidance (ConsistencyCheckPassed "clean"))
   (test $g_passed ""))

!(let* (($conf (memory-check-internal-conflicts))
        ($g_warn (format-consistency-guidance $conf)))
   (progn
     (test (sub_string_match $g_warn "CRITICAL MEMORY NOTICE") true)
     (test (sub_string_match $g_warn "ask_user") true)
     (println! "Test 6 PASSED: Formatted consistency notice contains warning and ask_user guidance.")))

!(println! "=== ALL MEMORY CONSISTENCY & STALENESS TESTS PASSED ===")
