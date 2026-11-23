;; =============================================================================
;; STAGE C - MILESTONE 9: Disk-Backed Persistence Process 1 (Writer)
;; File: tests/memory/test_memory_persistence_process1.metta
;; =============================================================================

!(println! "=== PROCESS 1: Starting Disk Persistence Writer ===")

!(import! &self "../../agent/memory_core.metta")

;; Reset stores and disk storage
!(memory-clear-all)
!(memory-clear-disk)

;; Store test memories
!(println! "--- Step 1: Populating long-term and episodic memories ---")
!(test (memory-store fact "PeTTa uses SWI-Prolog dynamic predicates.")
       (MemoryStoreSuccess "mem_1" fact "PeTTa uses SWI-Prolog dynamic predicates."))

!(test (memory-store preference "User prefers Markdown formatting.")
       (MemoryStoreSuccess "mem_2" preference "User prefers Markdown formatting."))

!(test (memory-store episodic "Session 1 successfully concluded.")
       (MemoryStoreSuccess "evt_1" episodic "Session 1 successfully concluded."))

;; Verify memory is saved to disk
!(println! "--- Step 2: Explicitly saving memory to disk ---")
!(test (memory-save-to-disk)
       (PersistenceSaveSuccess (long_term 2) (episodic 1)))

!(println! "=== PROCESS 1: Successfully saved to disk. Exiting. ===")
