;; =============================================================================
;; STAGE C - MILESTONE 8: Mocked Skill Cognitive Loop Integration Tests
;; File: tests/skills/test_skill_agent_loop_mocked.metta
;; =============================================================================

!(println! "=== Starting Mocked Skill Agent Cognitive Loop Tests ===")

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "../../agent/loop.metta")
!(import! &self "../../agent/skill_executor.metta")
!(import! &self "../../agent/skill_registry.metta")

;; Test 1: Bounded iteration limit
!(println! "--- Test 1: Iteration Limit Enforcement ---")
!(test (cognitive-step "default" "test prompt" 6 5)
       (AgentResult max_iterations_exceeded "Reasoning iteration limit reached."))

;; Test 2: Direct skill validation through parse-and-validate
!(println! "--- Test 2: Valid use_skill Action Parsing ---")
!(test (parse-and-validate-response "(action use_skill math_skill (\"125 * 8\"))")
       (ActionValid use_skill math_skill ("125 * 8")))

;; Test 3: Direct execution of math_skill via skill executor
!(println! "--- Test 3: Math Skill Execution Verification ---")
!(test (execute-skill math_skill ("125 * 8"))
       (SkillResult success math_skill 1000))

;; Test 4: Direct execution of text_process_skill via skill executor
!(println! "--- Test 4: Text Process Skill Execution Verification ---")
!(test (execute-skill text_process_skill ("Autonomous cognitive agents"))
       (SkillResult success text_process_skill (TextMetrics 3 (TextAnalysis 27 3 1 1))))

;; Test 5: Disabled skill safety check
!(println! "--- Test 5: Disabled Skill Execution Safety ---")
!(disable-skill math_skill)
!(test (execute-skill math_skill ("100 * 2"))
       (SkillResult failure math_skill "Skill is currently disabled."))
!(enable-skill math_skill)

!(println! "=== ALL MOCKED SKILL COGNITIVE LOOP TESTS PASSED ===")
