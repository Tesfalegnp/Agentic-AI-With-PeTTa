;; =============================================================================
;; STAGE C - MILESTONE 9: Multi-AtomSpace Memory Store & Audit Log
;; Module: agent/memory_store.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import_prolog_functions_from_file "agent/memory_io.pl" (save_records_from_space load_records_into_space clear_storage_file sub_string_match is_sensitive_text get_timestamp compute_record_relevance rank_records_in_space detect_preference_conflict detect_statement_conflict string_length_utf8 truncate_string_to_budget find_preference_conflicts_in_space find_statement_conflicts_in_space))
!(import! &self "memory_types.metta")

;; Dedicated AtomSpaces for memory isolation
!(bind! &short_term (new-space))
!(bind! &long_term (new-space))
!(bind! &episodic (new-space))
!(bind! &memory_history (new-space))

;; Generate unique stable ID for memory records
(= (generate-memory-id $prefix)
   (if (== $prefix "evt")
       (let* (($ep_recs (collapse (match &episodic (MemoryRecord $id $c $ty $co $cr $up $sr $pr $tg $st) $id)))
              ($total   (+ (length $ep_recs) 1)))
         (string_concat "evt_" (repr $total)))
       (let* (($lt_recs (collapse (match &long_term (MemoryRecord $id $c $ty $co $cr $up $sr $pr $tg $st) $id)))
              ($total   (+ (length $lt_recs) 1)))
         (string_concat "mem_" (repr $total)))))

;; Check for active duplicate entry in space
(= (memory-find-duplicate $space $category $content)
   (let $dups (collapse (match $space (MemoryRecord $id $category $ty $content $cr $up $sr $pr $tg active) $id))
     (if (== $dups ())
         false
         true)))

;; Record memory operation in history audit log
(= (history-record-memory-call $action $category $target $status $detail)
   (let* (($existing (collapse (match &memory_history (MemoryHistoryRecord $s $a $c $t $st $d) $s)))
          ($seq      (+ (length $existing) 1)))
     (progn
       (add-atom &memory_history (MemoryHistoryRecord $seq $action $category $target $status $detail))
       (MemoryHistoryRecorded $seq $action))))

;; Retrieve all memory history records
(= (memory-history-list)
   (collapse (match &memory_history (MemoryHistoryRecord $s $a $c $t $st $d)
               (MemoryHistoryEntry $s $a $c $t $st $d))))

;; Clear memory history
(= (memory-history-clear)
   (let $records (collapse (match &memory_history $x (remove-atom &memory_history $x)))
     "Memory history cleared."))
