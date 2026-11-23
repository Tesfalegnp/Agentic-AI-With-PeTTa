;; =============================================================================
;; STAGE C - MILESTONE 9: Memory Consolidation Unit Test Suite
;; File: tests/memory/test_memory_consolidation.metta
;; =============================================================================

!(println! "=== Starting Memory Consolidation Unit Tests ===")

!(import! &self "../../agent/memory_core.metta")

;; Reset stores
!(memory-clear-all)
!(memory-history-clear)
!(memory-clear-disk)

;; Test 1: Add transient items to short-term memory
!(println! "--- Test 1: Adding to Short-Term Memory ---")
!(memory-add-short-term fact "Transient fact: Temperature is 22C.")
!(memory-add-short-term preference "Transient preference: dark mode.")

;; Test 2: Clear short-term memory without affecting durable stores
!(println! "--- Test 2: Clear Short-term Memory Isolation ---")
!(test (memory-clear-short-term) "Short-term memory cleared.")
!(test (collapse (match &short_term $x $x)) ())

;; Test 3: Consolidation from short-term to long-term
!(println! "--- Test 3: Consolidating Short-Term to Long-Term ---")
!(memory-add-short-term fact "Durable fact: PeTTa version is 0.1.0.")
!(test (memory-consolidate) (ConsolidationResult (promoted 1)))
!(test (memory-recall fact "0.1.0")
       (MemoryRecallSuccess fact ("Durable fact: PeTTa version is 0.1.0.")))

;; Test 4: Record episodic event
!(println! "--- Test 4: Episodic Event Recording ---")
!(test (memory-record-episodic-event "milestone_9_started" "Started Milestone 9 implementation.")
       (EpisodicStored "evt_1"))
!(test (memory-recall episodic "Milestone 9")
       (MemoryRecallSuccess episodic ("Started Milestone 9 implementation.")))

!(println! "=== ALL MEMORY CONSOLIDATION TESTS PASSED ===")
