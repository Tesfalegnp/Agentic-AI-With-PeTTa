;; =============================================================================
;; STAGE D - MILESTONE 11: Plan & Task Execution Engine
;; Module: agent/plan_executor.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "plan_types.metta")
!(import! &self "plan_state.metta")
!(import! &self "plan_history.metta")
!(import! &self "task_scheduler.metta")
!(import! &self "tool_dispatcher.metta")
!(import! &self "tool_result.metta")
!(import! &self "skill_executor.metta")
!(import! &self "skill_result.metta")
!(import! &self "telemetry.metta")

;; Resolve single argument reference
(= (resolve-single-arg $plan_id $arg)
   (case $arg
     (((ref $dep_id)
       (let $dep (task-get $plan_id $dep_id)
         (case $dep
           (((PlanTask $dep_id $pid $desc $type $name $args $deps completed (TaskResult success $val))
             $val)
            ($_ (Error unresolved_reference $dep_id))))))
      ($val $val))))

;; Resolve argument list
(= (resolve-task-args $plan_id ()) ())
(= (resolve-task-args $plan_id $args)
   (let ($arg $rest) (decons-atom $args)
     (let* (($resolved_head (resolve-single-arg $plan_id $arg))
            ($resolved_tail (resolve-task-args $plan_id $rest)))
       (cons-atom $resolved_head $resolved_tail))))

;; Execute a single task step
(= (execute-task-step $plan_id $task_id)
   (let $task (task-get $plan_id $task_id)
     (case $task
       (((PlanTask $task_id $pid $desc $type $name $args $deps $status $res)
         (progn
           (task-update-status $plan_id $task_id running none)
           (plan-history-record $plan_id $task_id task_started "Executing task.")
           (let $resolved_args (resolve-task-args $plan_id $args)
             (progn
               (emit-telemetry "task_started" "execution" (string_concat "Executing plan task: " (repr $task_id)) (string_concat (repr $name) (string_concat " " (repr $resolved_args))))
               (case $type
                 ((tool
                   (let $tool_res (dispatch-tool $name $resolved_args)
                     (case $tool_res
                       (((ToolResult success $t $val)
                         (progn
                           (emit-telemetry "task_completed" "execution" (string_concat "Task completed: " (repr $task_id)) (repr $val))
                           (task-update-status $plan_id $task_id completed (TaskResult success $val))
                           (plan-history-record $plan_id $task_id task_completed (repr $val))
                           (TaskExecutionSuccess $task_id $val)))
                        ((ToolResult failure $t $err)
                         (progn
                           (emit-telemetry "task_failed" "recovery" (string_concat "Task failed: " (repr $task_id)) (repr $err))
                           (task-update-status $plan_id $task_id failed (TaskResult failure $err))
                           (plan-history-record $plan_id $task_id task_failed (repr $err))
                           (TaskExecutionFailure $task_id $err)))
                        ($_
                         (let $err "Malformed tool result."
                           (progn
                             (emit-telemetry "task_failed" "recovery" (string_concat "Task failed (malformed): " (repr $task_id)) $err)
                             (task-update-status $plan_id $task_id failed (TaskResult failure $err))
                             (plan-history-record $plan_id $task_id task_failed $err)
                             (TaskExecutionFailure $task_id $err))))))))
                  (skill
                   (let $skill_res (execute-skill $name $resolved_args)
                     (case $skill_res
                       (((SkillResult success $s $val)
                         (progn
                           (emit-telemetry "task_completed" "execution" (string_concat "Skill task completed: " (repr $task_id)) (repr $val))
                           (task-update-status $plan_id $task_id completed (TaskResult success $val))
                           (plan-history-record $plan_id $task_id task_completed (repr $val))
                           (TaskExecutionSuccess $task_id $val)))
                        ((SkillResult failure $s $err)
                         (progn
                           (emit-telemetry "task_failed" "recovery" (string_concat "Skill task failed: " (repr $task_id)) (repr $err))
                           (task-update-status $plan_id $task_id failed (TaskResult failure $err))
                           (plan-history-record $plan_id $task_id task_failed (repr $err))
                           (TaskExecutionFailure $task_id $err)))
                        ($_
                         (let $err "Malformed skill result."
                           (progn
                             (emit-telemetry "task_failed" "recovery" (string_concat "Skill task failed (malformed): " (repr $task_id)) $err)
                             (task-update-status $plan_id $task_id failed (TaskResult failure $err))
                             (plan-history-record $plan_id $task_id task_failed $err)
                             (TaskExecutionFailure $task_id $err))))))))
                  ($_ (TaskExecutionFailure $task_id "Unknown executor type."))))))))
        ($_ (TaskExecutionFailure $task_id "Task not found."))))))

;; Recursive plan execution loop
(= (execute-plan-loop $plan_id $iteration $max_iterations)
   (if (> $iteration $max_iterations)
       (PlanExecutionHalted $plan_id "Maximum plan execution steps exceeded.")
       (let $sched (schedule-next-task $plan_id)
         (case $sched
           (((NextTask $task_id)
             (let $_exec (execute-task-step $plan_id $task_id)
               (execute-plan-loop $plan_id (+ $iteration 1) $max_iterations)))
            ((AllTasksCompleted $pid)
             (progn
               (plan-update-status $plan_id completed)
               (plan-history-record $plan_id none plan_completed "All tasks in plan completed successfully.")
               (PlanExecutionSuccess $plan_id)))
            ((PlanBlocked $pid)
             (progn
               (plan-update-status $plan_id blocked)
               (plan-history-record $plan_id none plan_failed "Plan blocked due to failed task dependency.")
               (PlanExecutionBlocked $plan_id)))
            ((NoTasksReady)
             (PlanExecutionHalted $plan_id "No ready tasks found.")))))))

;; Main Plan Execution Entry Point
(= (execute-plan $plan_id)
   (progn
     (plan-update-status $plan_id executing)
     (execute-plan-loop $plan_id 1 15)))
