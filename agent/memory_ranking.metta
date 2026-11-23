;; =============================================================================
;; STAGE D - MILESTONE 10: Memory Relevance Ranking & Query-Aware Retrieval
;; Module: agent/memory_ranking.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "memory_store.metta")

;; Rank records in a given AtomSpace based on query, category filter and limit
(= (memory-rank-space $space $query $category $limit)
   (let $results (rank_records_in_space $space $query $category $limit)
     (if (== $results ())
         (MemoryRankedEmpty $category)
         (MemoryRankedSuccess $category $results))))

;; Unified query-aware memory retrieval across active persistent memories
(= (memory-retrieve-relevant $query $category $limit)
   (if (== $category episodic)
       (let $ep_res (rank_records_in_space &episodic $query episodic $limit)
         (if (== $ep_res ())
             (MemoryRetrieveEmpty episodic)
             (MemoryRetrieveSuccess episodic $ep_res)))
       (let $lt_res (rank_records_in_space &long_term $query $category $limit)
         (if (== $lt_res ())
             (MemoryRetrieveEmpty $category)
             (MemoryRetrieveSuccess $category $lt_res)))))

;; Extract pure MemoryRecord items from RankedMemory wrappers
(= (extract-records-from-ranked ()) ())
(= (extract-records-from-ranked ((RankedMemory $s $rec) $rest))
   (let $tail (extract-records-from-ranked $rest)
     ($rec $tail)))

;; Single record relevance score inspector
(= (memory-score-content $content $query $priority $timestamp)
   (compute_record_relevance $content $query $priority $timestamp))
