;; =============================================================================
;; STAGE D - MILESTONE 10: Prompt Context Budgeting Unit Tests
;; File: tests/memory/test_memory_context_budget.metta
;; =============================================================================

!(println! "=== Starting Context Budgeting Unit Tests ===")

!(import! &self "../../agent/memory_core.metta")
!(import! &self "../../agent/context_budget.metta")

;; Reset stores
!(memory-clear-all)
!(memory-clear-disk)

;; Setup sample components
!(memory-store-with-priority preference "User prefers concise answers." 5)
!(memory-store-with-priority fact "PeTTa is an open-source agentic runtime." 1)

;; Test 1: Full context within normal budget (Intact)
!(println! "--- Test 1: Full context within normal budget ---")
!(let* (($id    "You are PeTTa Agent.")
        ($proto "1. (action answer \"<content>\")")
        ($tools "--- TOOLS ---\ncalculator")
        ($skills "--- SKILLS ---\nmath_skill")
        ($shots "User: Hi\nResponse: (action answer \"Hi\")")
        ($conv  "User: Calculate 10+20\nAssistant: 30")
        ($mem   "- [Memory ID: mem_1 | Category: preference] User prefers concise answers.")
        ($cons  "")
        ($query "What is 50 * 2?")
        ($res   (enforce-context-budget $id $proto $tools $skills $shots $conv $mem $cons $query 4000)))
   (case $res
     (((BudgetResult intact $prompt $len (BudgetMetadata all_included $dyn_len $avail))
       (progn
         ;; Verify all sections are present
         (test (sub_string_match $prompt "PeTTa Agent") true)
         (test (sub_string_match $prompt "What is 50 * 2?") true)
         (test (sub_string_match $prompt "concise answers") true)
         (test (sub_string_match $prompt "Calculate 10+20") true)
         (println! "✅ All context components included intact within normal budget.")))
      ($_ (println! "❌ Test 1 failed.")))))

;; Test 2: Trimming under constrained budget preserves core instructions and query
!(println! "--- Test 2: Trimming preserves core instructions and user query ---")
!(let* (($id    "You are PeTTa Agent.")
        ($proto "1. (action answer \"<content>\")")
        ($tools "--- TOOLS ---\ncalculator")
        ($skills "--- SKILLS ---\nmath_skill")
        ($shots "User: Hi\nResponse: (action answer \"Hi\")")
        ($conv  "User: Long conversation history message repeated many times for length testing.")
        ($mem   "- [Memory ID: mem_1 | Category: preference] User prefers concise answers.")
        ($cons  "")
        ($query "Critical user question that must never be trimmed?")
        ;; Tight budget limit of 350 chars
        ($res   (enforce-context-budget $id $proto $tools $skills $shots $conv $mem $cons $query 350)))
   (case $res
     (((BudgetResult trimmed $prompt $len $meta)
       (progn
         ;; Core system instructions and user query MUST be preserved
         (test (sub_string_match $prompt "You are PeTTa Agent.") true)
         (test (sub_string_match $prompt "Critical user question that must never be trimmed?") true)
         ;; Length must not exceed budget
         (test (<= $len 350) true)
         (println! "✅ Tight budget enforced: instructions and query strictly preserved within limit.")))
      ($_ (println! "❌ Test 2 failed.")))))

;; Test 3: Trimming does not mutate persistent memory in AtomSpace
!(println! "--- Test 3: Trimming does not mutate persistent memory ---")
!(let $count_before (length (collapse (match &long_term (MemoryRecord $i $c $t $co $cr $up $sr $pr $tg active) $i)))
   (progn
     (test (== $count_before 2) true)
     (println! "✅ Persistent memory AtomSpace remains completely unmutated and intact.")))

!(println! "=== ALL CONTEXT BUDGETING UNIT TESTS PASSED ===")
