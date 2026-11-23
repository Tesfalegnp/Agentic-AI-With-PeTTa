;; =============================================================================
;; STAGE C - MILESTONE 8: Standardized Skill Results
;; Module: agent/skill_result.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)

;; Skill result constructors:
;; (SkillResult success $skill_name $value)
;; (SkillResult failure $skill_name $error_message)
;; (StepResult success $step_id $value)
;; (StepResult failure $step_id $error_message)

(= (make-skill-success $skill $val)
   (SkillResult success $skill $val))

(= (make-skill-failure $skill $err)
   (SkillResult failure $skill $err))

(= (make-step-success $step_id $val)
   (StepResult success $step_id $val))

(= (make-step-failure $step_id $err)
   (StepResult failure $step_id $err))

(= (is-skill-success (SkillResult success $s $v)) true)
(= (is-skill-success (SkillResult failure $s $e)) false)

(= (get-skill-result-value (SkillResult success $s $v)) $v)
(= (get-skill-result-value (SkillResult failure $s $e)) "")

(= (get-skill-result-error (SkillResult success $s $v)) "")
(= (get-skill-result-error (SkillResult failure $s $e)) $e)

;; Format skill result for insertion into cognitive loop prompt / context
(= (format-skill-observation $result)
   (case $result
     (((SkillResult success $skill $val)
       (string_concat "[Observation from skill " (string_concat (repr $skill) (string_concat "]: " (repr $val)))))
      ((SkillResult failure $skill $err)
       (string_concat "[Observation from skill " (string_concat (repr $skill) (string_concat " ERROR]: " (repr $err)))))
      ($_ "[Observation from skill]: Unknown skill result format."))))
