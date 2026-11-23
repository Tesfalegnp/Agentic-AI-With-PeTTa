;; =============================================================================
;; STAGE D - MILESTONE 10: Unified Context Manager & Provenance Tracking
;; Module: agent/context_manager.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "memory_ranking.metta")
!(import! &self "memory_consistency.metta")
!(import! &self "state.metta")

;; Format a single ranked memory record preserving full provenance metadata
(= (format-single-memory-provenance (RankedMemory $score (MemoryRecord $id $cat $ty $content $cr $up $sr $pr $tg active)))
   (let* (($p1   (string_concat "- [Memory ID: " $id))
          ($p2   (string_concat " | Category: " (repr $cat)))
          ($p3   (string_concat " | Priority: " (repr $pr)))
          ($p4   (string_concat " | Source: " (repr $sr)))
          ($p5   (string_concat " | Relevance: " (repr $score)))
          ($hdr  (string_concat $p1 (string_concat $p2 (string_concat $p3 (string_concat $p4 (string_concat $p5 "]\n"))))))
          ($body (string_concat "  Content: \"" (string_concat $content "\"\n"))))
     (string_concat $hdr $body)))

;; Recursively format a list of ranked memory records
(= (format-ranked-memory-list $list)
   (if (== $list ())
       ""
       (let* (($pair (decons-atom $list))
              ($head (car-atom $pair))
              ($tail (car-atom (cdr-atom $pair))))
         (string_concat (format-single-memory-provenance $head)
                        (format-ranked-memory-list $tail)))))

;; Retrieve and format only query-relevant persistent memories for context injection
(= (format-relevant-memories-context $query $max_memories)
   (let $retrieval (memory-retrieve-relevant $query all $max_memories)
     (case $retrieval
       (((MemoryRetrieveSuccess $cat $items)
         (let $formatted (format-ranked-memory-list $items)
           (if (== $formatted "")
               ""
               (string_concat "--- RELEVANT RETRIEVED MEMORIES (Active & Verified) ---\n"
                 (string_concat $formatted
                   "NOTE: These memories are contextual evidence. Do NOT fabricate or contradict without user confirmation.\n")))))
        ((MemoryRetrieveEmpty $cat) "")
        ($_ "")))))

;; Format recent conversation history (user, assistant, observations)
(= (format-managed-conversation-context)
   (let $history (state-get-context)
     $history))

;; Assemble complete managed context tuple: (ManagedContext $conv $mem $consistency)
(= (assemble-managed-context $query $max_memories)
   (let* (($conv        (format-managed-conversation-context))
          ($mem         (format-relevant-memories-context $query $max_memories))
          ($conflicts   (memory-check-internal-conflicts))
          ($consistency (format-consistency-guidance $conflicts)))
     (ManagedContext $conv $mem $consistency)))
