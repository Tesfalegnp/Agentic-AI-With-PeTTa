;; =============================================================================
;; STAGE C - MILESTONE 8: Built-in Skills Unit Test Suite
;; File: tests/skills/test_builtin_skills.metta
;; =============================================================================

!(println! "=== Starting Built-in Skills Unit Tests ===")

!(import! &self "../../skills/builtin/math_skill.metta")
!(import! &self "../../skills/builtin/text_process_skill.metta")
!(import! &self "../../skills/builtin/research_skill.metta")

;; 1. Math Skill Tests
!(println! "--- 1. Testing math_skill ---")
!(test (run-math-skill ("125 * 8"))
       (SkillResult success math_skill 1000))
!(test (run-math-skill ("50 / 0"))
       (SkillResult failure math_skill "Division by zero error."))
!(test (run-math-skill ())
       (SkillResult failure math_skill "Invalid argument count for math_skill."))

;; 2. Text Process Skill Tests
!(println! "--- 2. Testing text_process_skill ---")
!(test (run-text-process-skill ("Hello world from PeTTa"))
       (SkillResult success text_process_skill (TextMetrics 4 (TextAnalysis 22 4 1 1))))
!(test (run-text-process-skill ())
       (SkillResult failure text_process_skill "Invalid argument count for text_process_skill."))

;; 3. Research Skill Tests
!(println! "--- 3. Testing research_skill ---")
!(let (SkillResult success research_skill (ResearchReport $topic $dt $analysis $note))
      (run-research-skill ("Artificial Intelligence"))
   (println! (string_concat "Research skill executed successfully for: " $topic)))
!(test (run-research-skill ())
       (SkillResult failure research_skill "Invalid argument count for research_skill."))

!(println! "=== ALL BUILT-IN SKILL TESTS PASSED SUCCESSFULLY ===")
