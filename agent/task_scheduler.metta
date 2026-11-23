;; =============================================================================
;; STAGE D - MILESTONE 11: Dependency-Aware Task Scheduler
;; Module: agent/task_scheduler.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "plan_types.metta")
!(import! &self "plan_state.metta")
!(import! &self "plan_history.metta")

;; Evaluate status of a list of task dependencies
(= (check-deps-status $plan_id ()) DepsCompleted)
(= (check-deps-status $plan_id $deps)
   (let ($dep_id $rest) (decons-atom $deps)
     (let $dep_task (task-get $plan_id $dep_id)
       (case $dep_task
         (((PlanTask $dep_id $pid $desc $type $name $args $d completed $res)
           (check-deps-status $plan_id $rest))
          ((PlanTask $dep_id $pid $desc $type $name $args $d failed $res)
           DepsFailed)
          ((PlanTask $dep_id $pid $desc $type $name $args $d blocked $res)
           DepsFailed)
          ((PlanTask $dep_id $pid $desc $type $name $args $d cancelled $res)
           DepsFailed)
          ($_ DepsWaiting))))))

;; Update pending tasks to ready or blocked based on dependencies
(= (update-pending-tasks $plan_id ()) ())
(= (update-pending-tasks $plan_id $tasks)
   (let ($task $rest) (decons-atom $tasks)
     (case $task
       (((PlanTask $tid $pid $desc $type $name $args $deps pending $res)
         (let $dep_state (check-deps-status $plan_id $deps)
           (progn
             (case $dep_state
               ((DepsCompleted
                 (progn
                   (task-update-status $plan_id $tid ready none)
                   (plan-history-record $plan_id $tid task_scheduled "Dependencies satisfied; task ready.")))
                (DepsFailed
                 (progn
                   (task-update-status $plan_id $tid blocked (TaskResult failure "Dependency failed or blocked."))
                   (plan-history-record $plan_id $tid task_blocked "Dependency failed or blocked.")))
                ($_ ())))
             (update-pending-tasks $plan_id $rest))))
        ($_ (update-pending-tasks $plan_id $rest))))))

;; Count tasks by status
(= (count-tasks-with-status () $status) 0)
(= (count-tasks-with-status $tasks $status)
   (let ($task $rest) (decons-atom $tasks)
     (case $task
       (((PlanTask $tid $pid $desc $type $name $args $deps $st $res)
         (if (== $st $status)
             (+ 1 (count-tasks-with-status $rest $status))
             (count-tasks-with-status $rest $status)))
        ($_ (count-tasks-with-status $rest $status))))))

;; Filter ready tasks
(= (get-ready-tasks ()) ())
(= (get-ready-tasks $tasks)
   (let ($task $rest) (decons-atom $tasks)
     (case $task
       (((PlanTask $tid $pid $desc $type $name $args $deps ready $res)
         (cons-atom $tid (get-ready-tasks $rest)))
        ($_ (get-ready-tasks $rest))))))

;; Main Scheduling Entry Point
(= (schedule-next-task $plan_id)
   (let* (($tasks (plan-get-tasks $plan_id))
          ($_updated (update-pending-tasks $plan_id $tasks))
          ($refreshed_tasks (plan-get-tasks $plan_id))
          ($ready_ids (get-ready-tasks $refreshed_tasks)))
     (if (not (== $ready_ids ()))
         (NextTask (car-atom $ready_ids))
         (let* (($completed_count (count-tasks-with-status $refreshed_tasks completed))
                ($total_count     (length $refreshed_tasks))
                ($blocked_count   (count-tasks-with-status $refreshed_tasks blocked))
                ($failed_count    (count-tasks-with-status $refreshed_tasks failed)))
           (if (== $completed_count $total_count)
               (AllTasksCompleted $plan_id)
               (if (> (+ $blocked_count $failed_count) 0)
                   (PlanBlocked $plan_id)
                   (NoTasksReady)))))))
