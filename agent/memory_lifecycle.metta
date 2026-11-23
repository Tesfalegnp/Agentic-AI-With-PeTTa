;; =============================================================================
;; STAGE C - MILESTONE 9: Memory Lifecycle Operations
;; Module: agent/memory_lifecycle.metta
;; =============================================================================

!(import! &self "memory_store.metta")

;; Update an existing memory record content and updated_at timestamp
(= (memory-update $id $new_content)
   (let $found (collapse (match &long_term (MemoryRecord $id $cat $ty $co $cr $up $sr $pr $tg $st)
                           (progn
                             (remove-atom &long_term (MemoryRecord $id $cat $ty $co $cr $up $sr $pr $tg $st))
                             (add-atom &long_term (MemoryRecord $id $cat $ty $new_content $cr (get_timestamp) $sr $pr $tg active)))))
     (if (== $found ())
         (MemoryNotFound $id)
         (MemoryUpdateSuccess $id))))

;; Mark a memory record as superseded by a newer record
(= (memory-supersede $id $replacement_id)
   (let $found (collapse (match &long_term (MemoryRecord $id $cat $ty $co $cr $up $sr $pr $tg active)
                           (progn
                             (remove-atom &long_term (MemoryRecord $id $cat $ty $co $cr $up $sr $pr $tg active))
                             (add-atom &long_term (MemoryRecord $id $cat $ty $co $cr (get_timestamp) $sr $pr $tg superseded)))))
     (if (== $found ())
         (MemoryNotFound $id)
         (MemorySupersedeSuccess $id $replacement_id))))

;; Delete a memory record completely from long-term memory
(= (memory-delete $id)
   (let $found (collapse (match &long_term (MemoryRecord $id $cat $ty $co $cr $up $sr $pr $tg $st)
                           (remove-atom &long_term (MemoryRecord $id $cat $ty $co $cr $up $sr $pr $tg $st))))
     (if (== $found ())
         (MemoryNotFound $id)
         (MemoryDeleteSuccess $id))))

;; Update the priority rating of an existing active memory record (1 to 5)
(= (memory-set-priority $id $new_priority)
   (let $found (collapse (match &long_term (MemoryRecord $id $cat $ty $co $cr $up $sr $pr $tg active)
                           (progn
                             (remove-atom &long_term (MemoryRecord $id $cat $ty $co $cr $up $sr $pr $tg active))
                             (add-atom &long_term (MemoryRecord $id $cat $ty $co $cr (get_timestamp) $sr $new_priority $tg active)))))
     (if (== $found ())
         (MemoryNotFound $id)
         (MemoryPriorityUpdated $id $new_priority))))

;; Clear transient short-term memory without touching durable stores
(= (memory-clear-short-term)
   (let $cleared (collapse (match &short_term $x (remove-atom &short_term $x)))
     "Short-term memory cleared."))

;; Reset all memory stores and history
(= (memory-clear-all)
   (progn
     (collapse (match &short_term $x (remove-atom &short_term $x)))
     (collapse (match &long_term $x (remove-atom &long_term $x)))
     (collapse (match &episodic $x (remove-atom &episodic $x)))
     (collapse (match &memory_history $x (remove-atom &memory_history $x)))
     "All memory stores cleared."))
