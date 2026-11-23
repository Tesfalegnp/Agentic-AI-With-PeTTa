;; =============================================================================
;; STAGE C - MILESTONE 9: Memory Lifecycle Unit Test Suite
;; File: tests/memory/test_memory_lifecycle.metta
;; =============================================================================

!(println! "=== Starting Memory Lifecycle Unit Tests ===")

!(import! &self "../../agent/memory_core.metta")

;; Reset stores
!(memory-clear-all)
!(memory-history-clear)
!(memory-clear-disk)

;; Populate test memory
!(memory-store preference "User likes verbose explanations.")

;; Test 1: Update memory content
!(println! "--- Test 1: Memory Update ---")
!(test (memory-update "mem_1" "User prefers extremely concise bullet points.")
       (MemoryUpdateSuccess "mem_1"))
!(test (memory-recall preference "bullet")
       (MemoryRecallSuccess preference ("User prefers extremely concise bullet points.")))

;; Test 2: Supersede memory
!(println! "--- Test 2: Memory Superseding ---")
!(memory-store preference "User prefers Python examples.")
!(test (memory-supersede "mem_1" "mem_2")
       (MemorySupersedeSuccess "mem_1" "mem_2"))
;; Superseded record is excluded from active recall by default
!(test (memory-recall preference "bullet")
       (MemoryRecallEmpty preference))
!(test (memory-recall preference "Python")
       (MemoryRecallSuccess preference ("User prefers Python examples.")))

;; Test 3: Delete memory
!(println! "--- Test 3: Memory Deletion ---")
!(test (memory-delete "mem_2")
       (MemoryDeleteSuccess "mem_2"))
!(test (memory-recall preference "Python")
       (MemoryRecallEmpty preference))

;; Test 4: Non-existent ID handling
!(println! "--- Test 4: Non-existent Memory Handling ---")
!(test (memory-update "non_existent_id" "Content")
       (MemoryNotFound "non_existent_id"))
!(test (memory-delete "non_existent_id")
       (MemoryNotFound "non_existent_id"))

!(println! "=== ALL MEMORY LIFECYCLE TESTS PASSED ===")
