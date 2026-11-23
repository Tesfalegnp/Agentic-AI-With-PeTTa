;; =============================================================================
;; STAGE C - MILESTONE 9: Disk-Backed Persistence Process 2 (Reader & Verification)
;; File: tests/memory/test_memory_persistence_process2.metta
;; =============================================================================

!(println! "=== PROCESS 2: Starting Fresh Process for Persistence Verification ===")

!(import! &self "../../agent/memory_core.metta")

;; Initialize memory from disk
!(println! "--- Step 1: Initializing memory from disk in fresh process ---")
!(test (memory-init)
       (PersistenceLoadSuccess (long_term 2) (episodic 1)))

;; Verify restored memories match Process 1 exactly
!(println! "--- Step 2: Verifying restored memory content ---")
!(test (memory-recall fact "SWI-Prolog")
       (MemoryRecallSuccess fact ("PeTTa uses SWI-Prolog dynamic predicates.")))

!(test (memory-recall preference "Markdown")
       (MemoryRecallSuccess preference ("User prefers Markdown formatting.")))

!(test (memory-recall episodic "Session 1")
       (MemoryRecallSuccess episodic ("Session 1 successfully concluded.")))

;; Verify cross-space isolation
!(println! "--- Step 3: Verifying cross-space isolation ---")
!(test (memory-recall fact "Session 1")
       (MemoryRecallEmpty fact))

!(println! "=== PROCESS 2: PERSISTENCE ACROSS INDEPENDENT PROCESS RESTARTS VERIFIED ===")
