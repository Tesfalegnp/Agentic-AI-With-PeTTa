;; =============================================================================
;; STAGE C - MILESTONE 9: Unified Memory Subsystem Core & Entry Point
;; Module: agent/memory_core.metta
;; =============================================================================

!(import! &self "memory_store.metta")
!(import! &self "memory_types.metta")
!(import! &self "memory_validator.metta")
!(import! &self "memory_retrieval.metta")
!(import! &self "memory_lifecycle.metta")
!(import! &self "memory_consolidation.metta")
!(import! &self "memory_persistence.metta")
!(import! &self "memory_ranking.metta")
!(import! &self "memory_consistency.metta")

;; Store a memory record into long-term (or episodic) memory
(= (memory-store $category $content)
   (let $validation (validate-memory-input $category $content)
     (case $validation
       (((MemoryValidationSuccess $cat $text)
         (if (== $cat episodic)
             (if (== (memory-find-duplicate &episodic $cat $text) true)
                 (progn
                   (history-record-memory-call remember $cat $text duplicate "Duplicate episodic record")
                   (MemoryStoreDuplicate $cat $text))
                 (let* (($id       (generate-memory-id "evt"))
                        ($ts       (get_timestamp))
                        ($rec      (MemoryRecord $id episodic episodic $text $ts $ts user 1 () active))
                        ($_add     (add-atom &episodic $rec))
                        ($_persist (memory-save-to-disk))
                        ($_log     (history-record-memory-call remember episodic $id success $text)))
                   (MemoryStoreSuccess $id episodic $text)))
             (if (== (memory-find-duplicate &long_term $cat $text) true)
                 (progn
                   (history-record-memory-call remember $cat $text duplicate "Duplicate memory record")
                   (MemoryStoreDuplicate $cat $text))
                 (let* (($prefix   "mem")
                        ($id       (generate-memory-id $prefix))
                        ($ts       (get_timestamp))
                        ($type     (get-default-type-for-category $cat))
                        ($rec      (MemoryRecord $id $cat $type $text $ts $ts user 1 () active))
                        ($_add     (add-atom &long_term $rec))
                        ($_persist (memory-save-to-disk))
                        ($_log     (history-record-memory-call remember $cat $id success $text)))
                   (MemoryStoreSuccess $id $cat $text)))))

        ((MemoryValidationFailure $reason)
         (progn
           (history-record-memory-call remember $category "none" failure $reason)
           (MemoryStoreFailure $reason)))))))

;; Store a memory record with an explicit priority (1 to 5)
(= (memory-store-with-priority $category $content $priority)
   (let $validation (validate-memory-input $category $content)
     (case $validation
       (((MemoryValidationSuccess $cat $text)
         (if (== $cat episodic)
             (if (== (memory-find-duplicate &episodic $cat $text) true)
                 (progn
                   (history-record-memory-call remember $cat $text duplicate "Duplicate episodic record")
                   (MemoryStoreDuplicate $cat $text))
                 (let* (($id       (generate-memory-id "evt"))
                        ($ts       (get_timestamp))
                        ($rec      (MemoryRecord $id episodic episodic $text $ts $ts user $priority () active))
                        ($_add     (add-atom &episodic $rec))
                        ($_persist (memory-save-to-disk))
                        ($_log     (history-record-memory-call remember episodic $id success $text)))
                   (MemoryStoreSuccess $id episodic $text)))
             (if (== (memory-find-duplicate &long_term $cat $text) true)
                 (progn
                   (history-record-memory-call remember $cat $text duplicate "Duplicate memory record")
                   (MemoryStoreDuplicate $cat $text))
                 (let* (($prefix   "mem")
                        ($id       (generate-memory-id $prefix))
                        ($ts       (get_timestamp))
                        ($type     (get-default-type-for-category $cat))
                        ($rec      (MemoryRecord $id $cat $type $text $ts $ts user $priority () active))
                        ($_add     (add-atom &long_term $rec))
                        ($_persist (memory-save-to-disk))
                        ($_log     (history-record-memory-call remember $cat $id success $text)))
                   (MemoryStoreSuccess $id $cat $text)))))

        ((MemoryValidationFailure $reason)
         (progn
           (history-record-memory-call remember $category "none" failure $reason)
           (MemoryStoreFailure $reason)))))))

;; Recall memories by category and query string
(= (memory-recall-query $category $query)
   (let $res (memory-recall $category $query)
     (case $res
       (((MemoryRecallSuccess $cat $matches)
         (progn
           (history-record-memory-call recall $cat $query success (repr (length $matches)))
           (MemoryRecallSuccess $cat $matches)))
        ((MemoryRecallEmpty $cat)
         (progn
           (history-record-memory-call recall $cat $query empty "No matches found")
           (MemoryRecallEmpty $cat)))))))

;; Standardized observation formatter for cognitive loop
(= (format-memory-observation $result)
   (case $result
     (((MemoryStoreSuccess $id $cat $content)
       (string_concat "[Observation from memory remember]: Successfully remembered "
         (string_concat (repr $cat) (string_concat " with ID " (string_concat $id ".")))))

      ((MemoryStoreDuplicate $cat $content)
       (string_concat "[Observation from memory remember]: Information already exists in persistent memory under "
         (string_concat (repr $cat) ".")))

      ((MemoryStoreFailure $reason)
       (string_concat "[Observation from memory remember ERROR]: " $reason))

      ((MemoryRecallSuccess $cat $matches)
       (string_concat "[Observation from memory recall (" (string_concat (repr $cat) (string_concat ")]: " (repr $matches)))))

      ((MemoryRecallEmpty $cat)
       (string_concat "[Observation from memory recall (" (string_concat (repr $cat) ")]: No matching memories found.")))

      ((MemoryRetrieveSuccess $cat $matches)
       (string_concat "[Observation from memory recall (" (string_concat (repr $cat) (string_concat ")]: " (repr $matches)))))

      ((MemoryRetrieveEmpty $cat)
       (string_concat "[Observation from memory recall (" (string_concat (repr $cat) ")]: No matching memories found.")))

      ($_ "[Observation from memory]: Unknown memory operation result."))))

;; Subsystem startup initialization
(= (memory-init)
   (memory-load-from-disk))

;; Subsystem shutdown finalization
(= (memory-shutdown)
   (memory-save-to-disk))
