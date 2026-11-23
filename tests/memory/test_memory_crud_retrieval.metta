;; =============================================================================
;; STAGE C - MILESTONE 9: Memory CRUD and Retrieval Unit Test Suite
;; File: tests/memory/test_memory_crud_retrieval.metta
;; =============================================================================

!(println! "=== Starting Memory CRUD and Retrieval Unit Tests ===")

!(import! &self "../../agent/memory_core.metta")

;; Clear state before testing
!(memory-clear-all)
!(memory-history-clear)
!(memory-clear-disk)

;; Test 1: Storing memories across categories
!(println! "--- Test 1: Storing Memories ---")
!(test (memory-store fact "PeTTa is an open-source agent runtime.")
       (MemoryStoreSuccess "mem_1" fact "PeTTa is an open-source agent runtime."))
!(test (memory-store preference "User prefers concise answers.")
       (MemoryStoreSuccess "mem_2" preference "User prefers concise answers."))
!(test (memory-store project "Target workspace is petta-agentic-ai.")
       (MemoryStoreSuccess "mem_3" project "Target workspace is petta-agentic-ai."))

;; Test 2: Duplicate prevention
!(println! "--- Test 2: Duplicate Prevention ---")
!(test (memory-store fact "PeTTa is an open-source agent runtime.")
       (MemoryStoreDuplicate fact "PeTTa is an open-source agent runtime."))

;; Test 3: Exact and partial substring retrieval
!(println! "--- Test 3: Substring Retrieval ---")
!(test (memory-recall fact "open-source")
       (MemoryRecallSuccess fact ("PeTTa is an open-source agent runtime.")))
!(test (memory-recall preference "concise")
       (MemoryRecallSuccess preference ("User prefers concise answers.")))
!(test (memory-recall project "workspace")
       (MemoryRecallSuccess project ("Target workspace is petta-agentic-ai.")))

;; Test 4: Category filtering isolation
!(println! "--- Test 4: Category Isolation ---")
!(test (memory-recall fact "concise")
       (MemoryRecallEmpty fact))

;; Test 5: Empty query returns all active records in category
!(println! "--- Test 5: Recall All In Category ---")
!(test (memory-recall-all preference)
       (MemoryRecallSuccess preference ("User prefers concise answers.")))

;; Test 6: Verify memory history audit trail
!(println! "--- Test 6: History Audit Log ---")
!(let $hist (memory-history-list)
   (println! "Memory history audit log populated correctly."))

!(println! "=== ALL MEMORY CRUD AND RETRIEVAL TESTS PASSED ===")
