;; =============================================================================
;; STAGE C - MILESTONE 9: Disk-Backed Memory Persistence
;; Module: agent/memory_persistence.metta
;; =============================================================================

!(import! &self "memory_store.metta")

(= (long-term-file-path) "memory/long_term/long_term_store.data")
(= (episodic-file-path) "memory/episodic/episodic_store.data")

;; Save all long-term and episodic memory atoms to disk
(= (memory-save-to-disk)
   (let* (($lt_count (save_records_from_space (long-term-file-path) &long_term))
          ($ep_count (save_records_from_space (episodic-file-path) &episodic)))
     (PersistenceSaveSuccess (long_term $lt_count) (episodic $ep_count))))

;; Load persisted records from disk into target AtomSpaces
(= (memory-load-from-disk)
   (let* (($lt_count (load_records_into_space (long-term-file-path) &long_term))
          ($ep_count (load_records_into_space (episodic-file-path) &episodic)))
     (PersistenceLoadSuccess (long_term $lt_count) (episodic $ep_count))))

;; Clear persisted memory files from disk
(= (memory-clear-disk)
   (progn
     (clear_storage_file (long-term-file-path))
     (clear_storage_file (episodic-file-path))
     "Disk storage cleared."))
