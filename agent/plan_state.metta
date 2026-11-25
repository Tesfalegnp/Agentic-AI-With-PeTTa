;; =============================================================================
;; STAGE D - MILESTONE 11: Plan State & Storage Management
;; Module: agent/plan_state.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import_prolog_functions_from_file "agent/plan_io.pl" (validate_plan_graph clean_plan_string get_plan_timestamp compute_topological_sort is_planning_required))
!(import! &self "plan_types.metta")

!(bind! &plan_space (new-space))

;; Counter initialization
!(add-atom &plan_space (PlanCounter 0))

;; Next Plan ID generator
(= (plan-next-id)
   (let $c_atoms (collapse (match &plan_space (PlanCounter $c) $c))
     (let $current (if (== $c_atoms ()) 0 (car-atom $c_atoms))
       (let $next (+ $current 1)
         (progn
           (remove-atom &plan_space (PlanCounter $current))
           (add-atom &plan_space (PlanCounter $next))
           (string_concat "plan_" (repr $next)))))))

;; Create a new Plan
(= (plan-create $goal_id $description)
   (let* (($pid (plan-next-id))
          ($now (get_plan_timestamp)))
     (progn
       (add-atom &plan_space (Plan $pid $goal_id $description draft $now))
       (PlanCreated $pid))))

;; Retrieve a Plan by ID
(= (plan-get $plan_id)
   (let $found (collapse (match &plan_space (Plan $plan_id $gid $desc $status $created)
                                (Plan $plan_id $gid $desc $status $created)))
     (if (== $found ())
         (PlanNotFound $plan_id)
         (car-atom $found))))

;; Add a Task to a Plan (safely removing any prior task with same task_id and plan_id)
(= (plan-add-task $plan_id $task_id $description $executor_type $executor_name $arguments $dependencies)
   (progn
     (collapse (match &plan_space (PlanTask $task_id $plan_id $old_d $old_t $old_n $old_a $old_dp $old_s $old_r)
                      (remove-atom &plan_space (PlanTask $task_id $plan_id $old_d $old_t $old_n $old_a $old_dp $old_s $old_r))))
     (add-atom &plan_space (PlanTask $task_id $plan_id $description $executor_type $executor_name $arguments $dependencies pending none))
     (TaskAdded $plan_id $task_id)))

;; Retrieve all Tasks for a Plan
(= (plan-get-tasks $plan_id)
   (collapse (match &plan_space (PlanTask $tid $plan_id $desc $type $name $args $deps $status $res)
                    (PlanTask $tid $plan_id $desc $type $name $args $deps $status $res))))

;; Retrieve a specific Task
(= (task-get $plan_id $task_id)
   (let $found (collapse (match &plan_space (PlanTask $task_id $plan_id $desc $type $name $args $deps $status $res)
                                (PlanTask $task_id $plan_id $desc $type $name $args $deps $status $res)))
     (if (== $found ())
         (TaskNotFound $plan_id $task_id)
         (car-atom $found))))

;; Update Task Status and Result
(= (task-update-status $plan_id $task_id $new_status $result)
   (let $existing (collapse (match &plan_space (PlanTask $task_id $plan_id $desc $type $name $args $deps $status $old_res)
                                   (PlanTask $task_id $plan_id $desc $type $name $args $deps $status $old_res)))
     (if (== $existing ())
         (TaskNotFound $plan_id $task_id)
         (let (PlanTask $task_id $plan_id $desc $type $name $args $deps $old_status $old_res) (car-atom $existing)
           (progn
             (remove-atom &plan_space (PlanTask $task_id $plan_id $desc $type $name $args $deps $old_status $old_res))
             (add-atom &plan_space (PlanTask $task_id $plan_id $desc $type $name $args $deps $new_status $result))
             (TaskStatusUpdated $task_id $new_status))))))

;; Update Plan Status
(= (plan-update-status $plan_id $new_status)
   (let $existing (collapse (match &plan_space (Plan $plan_id $gid $desc $status $created)
                                   (Plan $plan_id $gid $desc $status $created)))
     (if (== $existing ())
         (PlanNotFound $plan_id)
         (let (Plan $plan_id $gid $desc $old_status $created) (car-atom $existing)
           (progn
             (remove-atom &plan_space (Plan $plan_id $gid $desc $old_status $created))
             (add-atom &plan_space (Plan $plan_id $gid $desc $new_status $created))
             (PlanStatusUpdated $plan_id $new_status))))))

;; Clear plan space
(= (plan-clear-all)
   (progn
     (collapse (match &plan_space $x (remove-atom &plan_space $x)))
     (add-atom &plan_space (PlanCounter 0))
     "Plan space cleared."))
