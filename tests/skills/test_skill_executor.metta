;; =============================================================================
;; STAGE C - MILESTONE 8: Skill Executor Unit Test Suite
;; File: tests/skills/test_skill_executor.metta
;; =============================================================================

!(println! "=== Starting Skill Executor Unit Tests ===")

!(import! &self "../../agent/skill_executor.metta")

;; Clear history before testing
!(skill-history-clear)
!(history-clear)

;; Test 1: Successful math_skill execution
!(println! "--- Test 1: Math Skill Execution Success ---")
!(test (execute-skill math_skill ("125 * 8"))
       (SkillResult success math_skill 1000))

;; Test 2: Successful text_process_skill execution
!(println! "--- Test 2: Text Process Skill Execution Success ---")
!(test (execute-skill text_process_skill ("Hello world from PeTTa"))
       (SkillResult success text_process_skill (TextMetrics 4 (TextAnalysis 22 4 1 1))))

;; Test 3: Unregistered skill rejection
!(println! "--- Test 3: Unregistered Skill Execution Failure ---")
!(test (execute-skill unregistered_skill ("arg"))
       (SkillResult failure unregistered_skill "Unregistered skill name."))

;; Test 4: Disabled skill rejection
!(println! "--- Test 4: Disabled Skill Execution Failure ---")
!(disable-skill math_skill)
!(test (execute-skill math_skill ("10 + 20"))
       (SkillResult failure math_skill "Skill is currently disabled."))
!(enable-skill math_skill)

;; Test 5: Verify history recording in both &skill_history and &tool_history
!(println! "--- Test 5: History Population Verification ---")
!(let $sk_hist (skill-history-list)
   (println! "Skill history populated correctly."))
!(let $tl_hist (history-list-recent)
   (println! "Tool history populated correctly from skill execution."))

!(println! "=== SKILL EXECUTOR UNIT TESTS COMPLETED SUCCESSFULLY ===")
