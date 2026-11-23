;; =============================================================================
;; STAGE C - MILESTONE 8: Skill Execution Engine
;; Module: agent/skill_executor.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "skill_registry.metta")
!(import! &self "skill_validator.metta")
!(import! &self "skill_history.metta")
!(import! &self "skill_result.metta")
!(import! &self "skill_context.metta")
!(import! &self "skill_workflow.metta")

;; Built-in skill implementations
!(import! &self "../skills/builtin/math_skill.metta")
!(import! &self "../skills/builtin/text_process_skill.metta")
!(import! &self "../skills/builtin/research_skill.metta")

;; Step counts for built-in skills (deterministic case pattern)
(= (get-skill-steps-count $skill)
   (case $skill
     ((math_skill 2)
      (text_process_skill 3)
      (research_skill 3)
      ($_ 1))))

;; Internal execution router
(= (execute-skill-internal $skill $args)
   (case $skill
     ((math_skill (run-math-skill $args))
      (text_process_skill (run-text-process-skill $args))
      (research_skill (run-research-skill $args))
      ($_ (make-skill-failure $skill "Unimplemented skill binding.")))))

;; Public Skill Execution Entry Point
;; Validates, executes, logs history, and returns structured result
(= (execute-skill $skill $args)
   (let $val_result (validate-skill-call $skill $args)
     (case $val_result
       (((SkillValidationSuccess $skill $validated_args)
         (let $res (execute-skill-internal $skill $validated_args)
           (case $res
             (((SkillResult success $s $val)
               (progn
                 (history-record-skill-call $s $validated_args success (repr $val) (get-skill-steps-count $s))
                 (SkillResult success $s $val)))
              ((SkillResult failure $s $err)
               (progn
                 (history-record-skill-call $s $validated_args failure $err (get-skill-steps-count $s))
                 (SkillResult failure $s $err)))
              ($_
               (let $err_res (make-skill-failure $skill "Malformed result returned by skill.")
                 (progn
                   (history-record-skill-call $skill $validated_args failure "Malformed result returned by skill." 1)
                   $err_res)))))))

        ((SkillValidationFailure $skill $reason)
         (let $err_res (make-skill-failure $skill $reason)
           (progn
             (history-record-skill-call $skill $args failure $reason 0)
             $err_res)))))))
