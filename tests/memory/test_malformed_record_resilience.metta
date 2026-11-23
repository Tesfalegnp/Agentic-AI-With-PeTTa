;; =============================================================================
;; STAGE C - MILESTONE 9: Malformed Storage & Code Injection Resilience Test
;; File: tests/memory/test_malformed_record_resilience.metta
;; =============================================================================

!(println! "=== Starting Malformed Record Resilience Tests ===")

!(import! &self "../../agent/memory_core.metta")

;; Reset stores
!(memory-clear-all)
!(memory-clear-disk)

;; Manually corrupt data file with malformed syntax and an injection attempt
!(let $fh (clear_storage_file "memory/long_term/long_term_store.data")
   (println! "Storage file cleared for injection test."))

!(import_prolog_functions_from_file "tests/memory/persistence_helper.pl" (write_atom_to_file))

!(write_atom_to_file "memory/long_term/long_term_store.data" "mem_rec(\"mem_1\", fact, semantic, \"Valid memory before corruption\", 100, 100, user, 1, [], active).")
;; Corrupted syntax line
!(write_atom_to_file "memory/long_term/long_term_store.data" "mem_rec(broken_syntax_line_without_closing_paren")
;; Malicious injection attempt
!(write_atom_to_file "memory/long_term/long_term_store.data" "!(system(\"echo INJECTION_ATTEMPT\")).")
;; Valid record after corruption
!(write_atom_to_file "memory/long_term/long_term_store.data" "mem_rec(\"mem_2\", fact, semantic, \"Valid memory after corruption\", 200, 200, user, 1, [], active).")

;; Load corrupted storage from disk
!(println! "--- Loading corrupted storage from disk ---")
!(test (memory-load-from-disk) (PersistenceLoadSuccess (long_term 2) (episodic 0)))

;; Verify both valid records were preserved
!(println! "--- Verifying valid records survived corruption ---")
!(test (memory-recall fact "before corruption")
       (MemoryRecallSuccess fact ("Valid memory before corruption")))

!(test (memory-recall fact "after corruption")
       (MemoryRecallSuccess fact ("Valid memory after corruption")))

!(println! "=== MALFORMED RECORD & INJECTION RESILIENCE VERIFIED ===")
