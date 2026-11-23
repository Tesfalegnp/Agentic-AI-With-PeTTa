;; =============================================================================
;; STAGE D - MILESTONE 11: Plan & Task Validator
;; Module: agent/plan_validator.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "plan_types.metta")
!(import! &self "plan_state.metta")
!(import! &self "plan_history.metta")
!(import! &self "tool_registry.metta")
!(import! &self "tool_validator.metta")
!(import! &self "skill_registry.metta")
!(import! &self "skill_validator.metta")

;; Check if an argument contains a dynamic reference (ref $id)
(= (has-ref-argument ()) false)
(= (has-ref-argument $args)
   (let ($head $tail) (decons-atom $args)
     (case $head
       (((ref $id) true)
        ($_ (has-ref-argument $tail))))))

;; Validate task references against its dependencies
(= (validate-task-refs () $deps) true)
(= (validate-task-refs $args $deps)
   (let ($head $tail) (decons-atom $args)
     (case $head
       (((ref $id)
         (if (== (is-dep-member $id $deps) true)
             (validate-task-refs $tail $deps)
             false))
        ($_ (validate-task-refs $tail $deps))))))

(= (is-dep-member $item ()) false)
(= (is-dep-member $item $list)
   (let ($head $tail) (decons-atom $list)
     (if (== $head $item)
         true
         (is-dep-member $item $tail))))

;; Validate a single PlanTask atom
(= (validate-single-task (PlanTask $tid $pid $desc $type $name $args $deps $status $res))
   (if (== (is-valid-executor-type $type) false)
       (TaskValidationFailure $tid (string_concat "Invalid executor type: " (repr $type)))
       (case $type
         ((tool
           (if (== (is-tool-registered $name) false)
               (TaskValidationFailure $tid (string_concat "Unregistered tool: " (repr $name)))
               (if (== (is-tool-enabled $name) false)
                   (TaskValidationFailure $tid (string_concat "Tool is disabled: " (repr $name)))
                   (if (== (has-ref-argument $args) true)
                       (if (== (validate-task-refs $args $deps) true)
                           (TaskValidationSuccess $tid)
                           (TaskValidationFailure $tid "Dynamic reference not declared in task dependencies."))
                       (case (validate-tool-call $name $args)
                         (((ToolValidationSuccess $n $a) (TaskValidationSuccess $tid))
                          ((ToolValidationFailure $n $r) (TaskValidationFailure $tid $r))
                          ($_ (TaskValidationFailure $tid "Tool argument validation error."))))))))
          (skill
           (if (== (is-skill-registered $name) false)
               (TaskValidationFailure $tid (string_concat "Unregistered skill: " (repr $name)))
               (if (== (is-skill-enabled $name) false)
                   (TaskValidationFailure $tid (string_concat "Skill is disabled: " (repr $name)))
                   (if (== (has-ref-argument $args) true)
                       (if (== (validate-task-refs $args $deps) true)
                           (TaskValidationSuccess $tid)
                           (TaskValidationFailure $tid "Dynamic reference not declared in task dependencies."))
                       (case (validate-skill-call $name $args)
                         (((SkillValidationSuccess $n $a) (TaskValidationSuccess $tid))
                          ((SkillValidationFailure $n $r) (TaskValidationFailure $tid $r))
                          ($_ (TaskValidationFailure $tid "Skill argument validation error."))))))))
          ($_ (TaskValidationFailure $tid "Unsupported executor."))))))

;; Validate all tasks in a list
(= (validate-task-list ()) (AllTasksValid))
(= (validate-task-list $tasks)
   (let ($task $rest) (decons-atom $tasks)
     (let $res (validate-single-task $task)
       (case $res
         (((TaskValidationSuccess $tid)
           (validate-task-list $rest))
          ((TaskValidationFailure $tid $reason)
           (TaskValidationFailure $tid $reason)))))))

;; Convert PlanTask atoms to Prolog task format for graph validation
(= (tasks-to-prolog-tuples ()) ())
(= (tasks-to-prolog-tuples $tasks)
   (let ($head $rest) (decons-atom $tasks)
     (case $head
       (((PlanTask $tid $pid $desc $type $name $args $deps $status $res)
         (let $prolog_rest (tasks-to-prolog-tuples $rest)
           (cons-atom (task $tid $type $name $args $deps) $prolog_rest)))))))

;; Validate Plan
(= (validate-plan $plan_id)
   (let $tasks (plan-get-tasks $plan_id)
     (if (== $tasks ())
         (PlanValidationFailure $plan_id "Plan contains no tasks.")
         (let* (($tuples (tasks-to-prolog-tuples $tasks))
                ($graph_eval (validate_plan_graph $tuples)))
           (case $graph_eval
             (((valid $msg)
               (let $task_eval (validate-task-list $tasks)
                 (case $task_eval
                   (((AllTasksValid)
                     (progn
                       (plan-update-status $plan_id validated)
                       (plan-history-record $plan_id none plan_validated "Plan validated successfully.")
                       (PlanValidationSuccess $plan_id)))
                    ((TaskValidationFailure $tid $reason)
                     (PlanValidationFailure $plan_id (string_concat "Task " (string_concat (repr $tid) (string_concat " validation failed: " $reason)))))))))
              ((error $err_msg)
               (PlanValidationFailure $plan_id $err_msg))))))))
