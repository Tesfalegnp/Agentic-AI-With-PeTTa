;; =============================================================================
;; STAGE C - MILESTONE 8: Skill Registry Unit Test Suite
;; File: tests/skills/test_skill_registry.metta
;; =============================================================================

!(println! "=== Starting Skill Registry Unit Tests ===")

!(import! &self "../../agent/skill_registry.metta")

;; Test 1: Built-in skills are registered
!(println! "--- Test 1: Built-in Skills Registration Verification ---")
!(test (is-skill-registered math_skill) true)
!(test (is-skill-registered text_process_skill) true)
!(test (is-skill-registered research_skill) true)
!(test (is-skill-registered non_existent_skill) false)

;; Test 2: Built-in skills are enabled by default
!(println! "--- Test 2: Enabled Status Verification ---")
!(test (is-skill-enabled math_skill) true)
!(test (is-skill-enabled text_process_skill) true)
!(test (is-skill-enabled research_skill) true)

;; Test 3: Disabling and re-enabling a skill
!(println! "--- Test 3: Disabling and Enabling Skills ---")
!(disable-skill math_skill)
!(test (is-skill-enabled math_skill) false)
!(enable-skill math_skill)
!(test (is-skill-enabled math_skill) true)

;; Test 4: Duplicate registration rejection
!(println! "--- Test 4: Duplicate Registration Handling ---")
!(test (register-skill math_skill "Duplicate" () () string true)
       (RegistrationDuplicate math_skill))

;; Test 5: Dynamic prompt formatting
!(println! "--- Test 5: Prompt Formatting ---")
!(let $prompt_skills (format-skills-for-prompt)
   (println! "Prompt skills successfully formatted."))

!(println! "=== SKILL REGISTRY UNIT TESTS COMPLETED SUCCESSFULLY ===")
