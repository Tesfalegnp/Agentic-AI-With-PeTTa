;; =============================================================================
;; STAGE C - MILESTONE 8: Skill Argument Validator
;; Module: agent/skill_validator.metta
;; =============================================================================

!(import! &self "skill_registry.metta")

;; Validates a skill invocation:
;; (validate-skill-call skill_name arguments_list)
;; Returns:
;;   (SkillValidationSuccess $skill_name $args)
;;   (SkillValidationFailure $skill_name $reason_message)

(= (validate-skill-call $skill $args)
   (if (not (is-skill-registered $skill))
       (SkillValidationFailure $skill "Unregistered skill name.")
       (if (not (is-skill-enabled $skill))
           (SkillValidationFailure $skill "Skill is currently disabled.")
           (case $skill
             ((math_skill
               (case $args
                 ((($expr) (SkillValidationSuccess math_skill $args))
                  ($_ (SkillValidationFailure math_skill "Math skill requires exactly 1 expression argument.")))))

              (text_process_skill
               (case $args
                 ((($text) (SkillValidationSuccess text_process_skill $args))
                  ($_ (SkillValidationFailure text_process_skill "Text process skill requires exactly 1 text argument.")))))

              (research_skill
               (case $args
                 ((($topic) (SkillValidationSuccess research_skill $args))
                  ($_ (SkillValidationFailure research_skill "Research skill requires exactly 1 topic argument.")))))

              ($_ (SkillValidationFailure $skill "No validation rule for registered skill.")))))))
