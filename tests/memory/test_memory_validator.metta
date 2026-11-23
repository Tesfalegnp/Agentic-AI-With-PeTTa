;; =============================================================================
;; STAGE C - MILESTONE 9: Memory Validator Unit Test Suite
;; File: tests/memory/test_memory_validator.metta
;; =============================================================================

!(println! "=== Starting Memory Validator Unit Tests ===")

!(import! &self "../../agent/memory_validator.metta")

;; Test 1: Valid memory categories and content
!(println! "--- Test 1: Valid Memory Inputs ---")
!(test (validate-memory-input fact "SWI-Prolog powers PeTTa")
       (MemoryValidationSuccess fact "SWI-Prolog powers PeTTa"))
!(test (validate-memory-input preference "User prefers concise answers")
       (MemoryValidationSuccess preference "User prefers concise answers"))
!(test (validate-memory-input goal "Complete Milestone 9 testing")
       (MemoryValidationSuccess goal "Complete Milestone 9 testing"))
!(test (validate-memory-input project "Repository is petta-agentic-ai")
       (MemoryValidationSuccess project "Repository is petta-agentic-ai"))
!(test (validate-memory-input episodic "Completed conversation session 1")
       (MemoryValidationSuccess episodic "Completed conversation session 1"))

;; Test 2: Invalid category rejection
!(println! "--- Test 2: Invalid Category Rejection ---")
!(test (validate-memory-input unsupported_category "Some valid content")
       (MemoryValidationFailure "Invalid or unsupported memory category."))

;; Test 3: Empty content rejection
!(println! "--- Test 3: Empty Content Rejection ---")
!(test (validate-memory-input fact "")
       (MemoryValidationFailure "Empty content cannot be stored in memory."))

;; Test 4: Sensitive credentials and keys rejection
!(println! "--- Test 4: Sensitive Credentials Rejection ---")
!(test (validate-memory-input fact "Here is my secret api_key: 123456")
       (MemoryValidationFailure "Sensitive data or credentials cannot be stored in persistent memory."))
!(test (validate-memory-input preference "My OpenAI token is sk-abcdef123456")
       (MemoryValidationFailure "Sensitive data or credentials cannot be stored in persistent memory."))
!(test (validate-memory-input fact "Database password is supersecretpass")
       (MemoryValidationFailure "Sensitive data or credentials cannot be stored in persistent memory."))

!(println! "=== ALL MEMORY VALIDATOR TESTS PASSED SUCCESSFULLY ===")
