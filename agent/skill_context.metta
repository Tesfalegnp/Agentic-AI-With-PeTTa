;; =============================================================================
;; STAGE C - MILESTONE 8: Skill Workflow Execution Context
;; Module: agent/skill_context.metta
;; =============================================================================

;; Dedicated AtomSpace for workflow intermediate execution state
!(bind! &workflow_context (new-space))

;; Initialize / reset workflow context for a new execution
(= (context-init)
   (let $cleared (collapse (match &workflow_context $x (remove-atom &workflow_context $x)))
     "Context initialized."))

;; Store intermediate result for a workflow step
(= (context-store $step_id $val)
   (progn
     (add-atom &workflow_context (StepOutput $step_id $val))
     (Stored $step_id)))

;; Retrieve intermediate result for a workflow step
(= (context-get $step_id)
   (let $res (collapse (match &workflow_context (StepOutput $step_id $val) $val))
     (case $res
       ((($val) $val)
        ($_ (Error missing_step_result $step_id))))))

;; Clear all atoms in workflow context
(= (context-clear)
   (let $cleared (collapse (match &workflow_context $x (remove-atom &workflow_context $x)))
     "Context cleared."))
