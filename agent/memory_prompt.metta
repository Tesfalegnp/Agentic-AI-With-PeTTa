;; =============================================================================
;; STAGE C - MILESTONE 9: Dynamic Memory Prompt Formatter
;; Module: agent/memory_prompt.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function atomic_list_concat)
!(import_prolog_function string_concat)
!(import! &self "memory_store.metta")

;; Format active durable memories bounded to top 5 for dynamic prompt injection
(= (format-recalled-memories-for-prompt)
   (let $entries (collapse (match &long_term (MemoryRecord $id $cat $ty $content $cr $up $sr $pr $tg active)
                             (string_concat "- [" (string_concat (repr $cat) (string_concat "]: " $content)))))
     (if (== $entries ())
         ""
         (string_concat "--- RECALLED PERSISTENT MEMORIES ---\n"
           (string_concat (atomic_list_concat $entries "\n") "\n")))))
