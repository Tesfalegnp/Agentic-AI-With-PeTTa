;; =============================================================================
;; STAGE D - MILESTONE 10: Prompt Context Budgeting Engine
;; Module: agent/context_budget.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function atomic_list_concat)
!(import_prolog_function string_concat)
!(import! &self "memory_store.metta")

;; Configurable default context budget in UTF-8 characters (~4000 tokens)
(= (get-default-context-budget) 16000)

;; Calculate total length of string using Prolog UTF-8 helper
(= (calculate-string-budget $str)
   (string_length_utf8 $str))

;; Assemble prompt with strict budget enforcement
;; Mandatory components ($identity, $protocol, $tools, $skills, $shots, $query) are NEVER dropped.
(= (enforce-context-budget $id $proto $tools $skills $shots $conv $mem $cons $query $budget_limit)
   (enforce-context-budget-with-adaptation $id $proto $tools $skills $shots $conv $mem $cons "" $query $budget_limit))

(= (enforce-context-budget-with-adaptation $id $proto $tools $skills $shots $conv $mem $cons $adapt $query $budget_limit)
   (let* (($core_prompt (atomic_list_concat ($id $proto $tools $skills $shots) "\n\n"))
          ($query_sec   (string_concat "\n--- CURRENT USER QUERY ---\nUser: " (string_concat $query "\nResponse: ")))
          ($core_len    (calculate-string-budget (string_concat $core_prompt $query_sec)))
          ($avail_budget (- $budget_limit $core_len)))
     (if (<= $avail_budget 0)
         ;; Budget is severely constrained; keep only mandatory core prompt and user query
         (let* (($minimal_prompt (string_concat $core_prompt $query_sec))
                ($final_len      (calculate-string-budget $minimal_prompt)))
           (BudgetResult trimmed $minimal_prompt $final_len (BudgetMetadata core_only 0 0)))
         ;; Budget has room for dynamic context
         (let* (($mem_sec    (if (== $mem "") "" (string_concat "\n" (string_concat $mem "\n"))))
                ($conv_sec   (if (== $conv "") "" (string_concat "\n--- CURRENT CONVERSATION CONTEXT ---\n" (string_concat $conv "\n"))))
                ($cons_sec   (if (== $cons "") "" (string_concat "\n" (string_concat $cons "\n"))))
                ($adapt_sec  (if (== $adapt "") "" (string_concat "\n" (string_concat $adapt "\n"))))
                ($dyn_full   (string_concat $adapt_sec (string_concat $cons_sec (string_concat $mem_sec $conv_sec))))
                ($dyn_len    (calculate-string-budget $dyn_full)))
           (if (<= $dyn_len $avail_budget)
               ;; Everything fits within budget
               (let* (($full_prompt (string_concat $core_prompt (string_concat $dyn_full $query_sec)))
                      ($full_len    (calculate-string-budget $full_prompt)))
                 (BudgetResult intact $full_prompt $full_len (BudgetMetadata all_included $dyn_len $avail_budget)))
               ;; Dynamic context exceeds budget; truncate dynamic content to strictly fit $avail_budget
               (let* (($truncated_dyn (truncate_string_to_budget $dyn_full $avail_budget))
                      ($final_prompt  (string_concat $core_prompt (string_concat $truncated_dyn $query_sec)))
                      ($final_len     (calculate-string-budget $final_prompt)))
                 (BudgetResult trimmed $final_prompt $final_len (BudgetMetadata context_trimmed $avail_budget $dyn_len))))))))
