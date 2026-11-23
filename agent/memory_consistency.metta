;; =============================================================================
;; STAGE D - MILESTONE 10: Memory Consistency & Staleness Manager
;; Module: agent/memory_consistency.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "memory_store.metta")

;; Check for internal conflicts between active memory records
(= (memory-check-internal-conflicts)
   (let $conflicts (find_preference_conflicts_in_space &long_term)
     (if (== $conflicts ())
         (ConsistencyCheckPassed "No internal memory conflicts detected.")
         (ConsistencyConflictDetected $conflicts))))

;; Check whether a new statement or query conflicts with existing stored preferences
(= (memory-check-statement-conflict $statement)
   (let $conflicts (find_statement_conflicts_in_space &long_term $statement)
     (if (== $conflicts ())
         (StatementConsistent $statement)
         (StatementConflictDetected $conflicts))))

;; Check staleness of an active memory record by age threshold
(= (check-record-staleness $id $max_age_seconds)
   (let $found (collapse (match &long_term (MemoryRecord $id $cat $ty $co $cr $up $sr $pr $tg active) $cr))
     (if (== $found ())
         (StalenessCheckError "Record not found or not active.")
         (let* (($now (get_timestamp))
                ($cr  (car-atom $found))
                ($age (- $now $cr)))
           (if (>= $age $max_age_seconds)
               (RecordStale $id $age)
               (RecordFresh $id $age))))))

;; Format structured consistency warnings for prompt context
(= (format-consistency-guidance $conflicts)
   (case $conflicts
     (((ConsistencyCheckPassed $msg) "")
      ((ConsistencyConflictDetected $items)
       (string_concat "\n[CRITICAL MEMORY NOTICE: Contradictory active memory preferences detected: "
         (string_concat (repr $items) ".\nYou MUST ask the user for clarification (action ask_user ...) rather than assuming one over the other.]\n")))
      ($_ ""))))
