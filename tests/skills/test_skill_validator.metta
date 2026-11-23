;; =============================================================================
;; STAGE C - MILESTONE 8: Skill Validator Unit Test Suite
;; File: tests/skills/test_skill_validator.metta
;; =============================================================================

!(println! "=== Starting Skill Validator Unit Tests ===")

!(import! &self "../../agent/skill_validator.metta")

;; Test 1: Valid invocations for built-in skills
!(println! "--- Test 1: Valid Skill Arguments ---")
!(test (validate-skill-call math_skill ("125 * 8"))
       (SkillValidationSuccess math_skill ("125 * 8")))
!(test (validate-skill-call text_process_skill ("Analyze this input string."))
       (SkillValidationSuccess text_process_skill ("Analyze this input string.")))
!(test (validate-skill-call research_skill ("Cognitive Architectures"))
       (SkillValidationSuccess research_skill ("Cognitive Architectures")))

;; Test 2: Invalid argument counts (missing/extra)
!(println! "--- Test 2: Invalid Argument Counts ---")
!(test (validate-skill-call math_skill ())
       (SkillValidationFailure math_skill "Math skill requires exactly 1 expression argument."))
!(test (validate-skill-call math_skill ("1 + 1" "extra"))
       (SkillValidationFailure math_skill "Math skill requires exactly 1 expression argument."))
!(test (validate-skill-call text_process_skill ())
       (SkillValidationFailure text_process_skill "Text process skill requires exactly 1 text argument."))
!(test (validate-skill-call research_skill ())
       (SkillValidationFailure research_skill "Research skill requires exactly 1 topic argument."))

;; Test 3: Unregistered skill
!(println! "--- Test 3: Unregistered Skill Rejection ---")
!(test (validate-skill-call unknown_skill ("arg"))
       (SkillValidationFailure unknown_skill "Unregistered skill name."))

;; Test 4: Disabled skill
!(println! "--- Test 4: Disabled Skill Rejection ---")
!(disable-skill math_skill)
!(test (validate-skill-call math_skill ("100 * 2"))
       (SkillValidationFailure math_skill "Skill is currently disabled."))
!(enable-skill math_skill)

!(println! "=== SKILL VALIDATOR UNIT TESTS COMPLETED SUCCESSFULLY ===")
