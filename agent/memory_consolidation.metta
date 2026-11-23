;; =============================================================================
;; STAGE C - MILESTONE 9: Memory Consolidation
;; Module: agent/memory_consolidation.metta
;; =============================================================================

!(import! &self "memory_store.metta")

;; Add a temporary item to short-term working memory
(= (memory-add-short-term $category $content)
   (add-atom &short_term (ShortTermMemory $category $content)))

;; Promote unique short-term items to long-term memory
(= (memory-consolidate)
   (let* (($st_items (collapse (match &short_term (ShortTermMemory $cat $content) ($cat $content))))
          ($promoted (collapse (match &short_term (ShortTermMemory $cat $content)
                                 (if (== (memory-find-duplicate &long_term $cat $content) false)
                                     (let* (($id  (generate-memory-id "mem"))
                                            ($ts  (get_timestamp))
                                            ($rec (MemoryRecord $id $cat semantic $content $ts $ts agent 1 () active)))
                                       (progn
                                         (add-atom &long_term $rec)
                                         (Promoted $id)))
                                     (empty)))))
          ($_clear   (collapse (match &short_term $x (remove-atom &short_term $x)))))
     (ConsolidationResult (promoted (length $promoted)))))

;; Record an episodic event into &episodic store
(= (memory-record-episodic-event $event_name $summary)
   (let* (($id  (generate-memory-id "evt"))
          ($ts  (get_timestamp))
          ($rec (MemoryRecord $id episodic episodic $summary $ts $ts agent 2 ($event_name) active)))
     (progn
       (add-atom &episodic $rec)
       (EpisodicStored $id))))
