;; =============================================================================
;; STAGE C - MILESTONE 9: Memory Retrieval Engine
;; Module: agent/memory_retrieval.metta
;; =============================================================================

!(import! &self "memory_store.metta")

;; Check if a record matches query
(= (matches-query $content $query)
   (if (or (== $query "") (or (== $query "*") (== $query "all")))
       true
       (sub_string_match $content $query)))

;; Recall memories by category and query
(= (memory-recall $category $query)
   (if (== $category episodic)
       (let $matches (collapse (match &episodic (MemoryRecord $id episodic $ty $content $cr $up $sr $pr $tg active)
                                 (if (== (matches-query $content $query) true)
                                     $content
                                     (empty))))
         (if (== $matches ())
             (MemoryRecallEmpty episodic)
             (MemoryRecallSuccess episodic $matches)))
       (let $matches (collapse (match &long_term (MemoryRecord $id $category $ty $content $cr $up $sr $pr $tg active)
                                 (if (== (matches-query $content $query) true)
                                     $content
                                     (empty))))
         (if (== $matches ())
             (MemoryRecallEmpty $category)
             (MemoryRecallSuccess $category $matches)))))

;; Recall all active records in category
(= (memory-recall-all $category)
   (memory-recall $category "*"))
