;; =============================================================================
;; STAGE D - MILESTONE 11: Goal & Plan Completion Verifier
;; Module: agent/plan_verifier.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "plan_types.metta")
!(import! &self "goal_manager.metta")
!(import! &self "plan_state.metta")
!(import! &self "plan_history.metta")

;; Verify that all tasks have completed with valid outputs
(= (verify-task-results ()) (AllTasksVerified))
(= (verify-task-results $tasks)
   (let ($task $rest) (decons-atom $tasks)
     (case $task
       (((PlanTask $tid $pid $desc $type $name $args $deps completed (TaskResult success $val))
         (verify-task-results $rest))
        ((PlanTask $tid $pid $desc $type $name $args $deps $status $res)
         (TaskVerificationFailed $tid (string_concat "Task status is not completed: " (repr $status))))))))

;; Main Goal & Plan Verification Entry Point
(= (verify-plan-completion $goal_id $plan_id)
   (let $plan (plan-get $plan_id)
     (case $plan
       (((Plan $p $g $desc $status $created)
         (if (not (== $status completed))
             (GoalIncomplete $goal_id (string_concat "Plan status is not completed: " (repr $status)))
             (let $tasks (plan-get-tasks $plan_id)
               (if (== $tasks ())
                   (GoalIncomplete $goal_id "Plan has no tasks.")
                   (let $tasks_check (verify-task-results $tasks)
                     (case $tasks_check
                       (((AllTasksVerified)
                         (progn
                           (goal-update-status $goal_id completed)
                           (plan-history-record $plan_id none goal_verified "All tasks completed and verified; goal satisfied.")
                           (GoalVerified $goal_id $plan_id)))
                        ((TaskVerificationFailed $tid $reason)
                         (GoalIncomplete $goal_id (string_concat "Task " (string_concat (repr $tid) (string_concat " verification failed: " $reason))))))))))))
        ($_ (GoalIncomplete $goal_id "Plan not found."))))))
