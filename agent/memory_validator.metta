;; =============================================================================
;; STAGE C - MILESTONE 9: Memory Input & Security Validator
;; Module: agent/memory_validator.metta
;; =============================================================================

!(import! &self "memory_store.metta")
!(import! &self "memory_types.metta")

(= (validate-memory-input $category $content)
   (if (== $content "")
       (MemoryValidationFailure "Empty content cannot be stored in memory.")
       (if (== (is_sensitive_text $content) true)
           (MemoryValidationFailure "Sensitive data or credentials cannot be stored in persistent memory.")
           (if (not (is-valid-memory-category $category))
               (MemoryValidationFailure "Invalid or unsupported memory category.")
               (MemoryValidationSuccess $category $content)))))
