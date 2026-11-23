;; =============================================================================
;; STAGE C - MILESTONE 8: Multi-Step Workflow Engine
;; Module: agent/skill_workflow.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "skill_context.metta")
!(import! &self "skill_result.metta")
!(import! &self "tool_dispatcher.metta")

;; Maximum step limit for any workflow execution
(= (max-workflow-steps) 10)

;; Reference resolution from workflow context
(= (workflow-resolve-ref (ref $step_id))
   (context-get $step_id))
(= (workflow-resolve-ref $val)
   $val)

;; Step execution dispatcher
(= (workflow-execute-step (tool_step $id $tool $args))
   (let $res (dispatch-tool $tool $args)
     (case $res
       (((ToolResult success $t $val)
         (progn
           (context-store $id $val)
           (StepResult success $id $val)))
        ((ToolResult failure $t $err)
         (StepResult failure $id $err))
        ($_ (StepResult failure $id "Malformed tool result."))))))

(= (workflow-execute-step (transform_step $id identity (ref $ref_id)))
   (let $val (context-get $ref_id)
     (case $val
       (((Error missing_step_result $missing)
         (StepResult failure $id (string_concat "Missing reference step: " (repr $missing))))
        ($_
         (progn
           (context-store $id $val)
           (StepResult success $id $val)))))))

(= (workflow-execute-step (combine_step $id combine_two (ref $ref1) (ref $ref2)))
   (let* (($v1 (context-get $ref1))
          ($v2 (context-get $ref2)))
     (case $v1
       (((Error missing_step_result $m1)
         (StepResult failure $id (string_concat "Missing reference step: " (repr $m1))))
        ($_
         (case $v2
           (((Error missing_step_result $m2)
             (StepResult failure $id (string_concat "Missing reference step: " (repr $m2))))
            ($_
             (let $combined (Combined $v1 $v2)
               (progn
                 (context-store $id $combined)
                 (StepResult success $id $combined)))))))))))
