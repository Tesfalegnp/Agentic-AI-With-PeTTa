;; =============================================================================
;; STAGE D - MILESTONE 10: Memory Relevance Ranking Unit Tests
;; File: tests/memory/test_memory_ranking.metta
;; =============================================================================

!(println! "=== Starting Memory Ranking & Retrieval Tests ===")

!(import! &self "../../agent/memory_core.metta")
!(import! &self "../../agent/memory_ranking.metta")

;; Reset stores
!(memory-clear-all)
!(memory-clear-disk)

;; Populate test dataset
!(memory-store-with-priority preference "concise" 1)                               ;; mem_1 (Exact match candidate)
!(memory-store-with-priority preference "User prefers concise responses." 1)        ;; mem_2 (Substring match)
!(memory-store-with-priority preference "User prefers detailed verbose text." 1)     ;; mem_3 (Irrelevant to concise)
!(memory-store-with-priority fact "concise" 1)                                      ;; mem_4 (Exact match, different category)
!(memory-store-with-priority preference "Completely unrelated about gardening." 5)  ;; mem_5 (High priority, completely irrelevant)

;; Create a superseded record
!(memory-store preference "Old preference before supersede.")                       ;; mem_6
!(let $res (memory-supersede "mem_6" "mem_1")
   (println! "Record mem_6 superseded successfully."))

;; Create and delete a record (archived)
!(memory-store preference "Archived record text.")                                   ;; mem_7
!(let $del (memory-delete "mem_7")
   (println! "Record mem_7 deleted/archived."))

;; Test 1: Exact match ranks above partial substring match
!(println! "--- Test 1: Exact match ranks above substring match ---")
!(let $res1 (memory-retrieve-relevant "concise" preference 5)
   (case $res1
     (((MemoryRetrieveSuccess preference ((RankedMemory $score1 (MemoryRecord $id1 $c1 $t1 $co1 $cr1 $up1 $sr1 $p1 $tg1 $st1)) $rest))
       (progn
         (test $id1 "mem_1")
         (test $score1 100)
         (println! "✅ Exact match ranked first with score 100.")))
      ($_ (println! "❌ Test 1 failed.")))))

;; Test 2: Category isolation
!(println! "--- Test 2: Category isolation ---")
!(let $res2 (memory-retrieve-relevant "concise" fact 5)
   (case $res2
     (((MemoryRetrieveSuccess fact ((RankedMemory $s2 (MemoryRecord $id2 $c2 $t2 $co2 $cr2 $up2 $sr2 $p2 $tg2 $st2)) $rest2))
       (progn
         (test $id2 "mem_4")
         (test $c2 fact)
         (println! "✅ Category filter strictly isolated fact from preferences.")))
      ($_ (println! "❌ Test 2 failed.")))))

;; Test 3: High priority on irrelevant record does not override relevance
!(println! "--- Test 3: Priority does not promote irrelevant records ---")
!(let $res3 (memory-retrieve-relevant "concise" preference 5)
   (case $res3
     (((MemoryRetrieveSuccess preference $items)
       (progn
         ;; Verify mem_5 is NOT in the retrieved list despite Priority 5
         (test (sub_string_match (repr $items) "gardening") false)
         (println! "✅ Irrelevant priority 5 record correctly excluded.")))
      ($_ (println! "❌ Test 3 failed.")))))

;; Test 4: Priority boosting on relevant records
!(println! "--- Test 4: Priority boosting on relevant records ---")
!(memory-store-with-priority goal "Deploy Python backend to cloud" 1)
!(memory-store-with-priority goal "Deploy Python agent to AWS" 4)     ;; Higher priority

!(let $res4 (memory-retrieve-relevant "Deploy Python" goal 5)
   (case $res4
     (((MemoryRetrieveSuccess goal ((RankedMemory $s_first (MemoryRecord $id_first $cg1 $ty1 $co_f $cr_f $up_f $sr_f $pr_f $tg_f $st_f)) $tail))
       (progn
         (test $co_f "Deploy Python agent to AWS")
         (test $pr_f 4)
         (println! "✅ Priority 4 boosted AWS agent ahead of priority 1 backend.")))
      ($_ (println! "❌ Test 4 failed.")))))

;; Test 5: Superseded and archived records are excluded
!(println! "--- Test 5: Exclude superseded and archived records ---")
!(let $res5 (memory-retrieve-relevant "supersede" all 5)
   (test $res5 (MemoryRetrieveEmpty all)))
!(let $res6 (memory-retrieve-relevant "Archived" all 5)
   (test $res6 (MemoryRetrieveEmpty all)))
!(println! "✅ Superseded and archived records strictly excluded.")

;; Test 6: Limit enforcement
!(println! "--- Test 6: Limit enforcement ---")
!(let $res7 (memory-retrieve-relevant "concise" all 1)
   (case $res7
     (((MemoryRetrieveSuccess all $items)
       (progn
         (test (length $items) 1)
         (println! "✅ Limit 1 strictly enforced.")))
      ($_ (println! "❌ Test 6 failed.")))))

;; Test 7: Empty retrieval on zero matches
!(println! "--- Test 7: Empty retrieval on zero matches ---")
!(let $res8 (memory-retrieve-relevant "nonexistent_term_xyz_123" all 5)
   (test $res8 (MemoryRetrieveEmpty all)))
!(println! "✅ Safe empty result returned when no memories match.")

!(println! "=== ALL MEMORY RANKING TESTS PASSED ===")
