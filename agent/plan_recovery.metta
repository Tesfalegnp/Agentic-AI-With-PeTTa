;; =============================================================================
;; STAGE D - MILESTONE 11: Plan Failure Recovery & Bounded Replanning
;; Module: agent/plan_recovery.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "plan_types.metta")
!(import! &self "plan_state.metta")
!(import! &self "plan_history.metta")

!(bind! &recovery_space (new-space))

;; Max limits
(= (max-task-retries) 1)
(= (max-goal-replans) 1)

;; Check whether an error is non-recoverable
(= (is-non-recoverable-error $err)
   (if (or (== $err "Division by zero error.")
       (or (== $err "Invalid argument count.")
       (or (== $err "Unregistered tool.")
       (or (== $err "Tool is disabled.")
       (or (== $err "Skill is disabled.")
           (== $err "Unknown executor type."))))))
       true
       false))

;; Check if task can be retried
(= (can-retry-task $plan_id $task_id $error)
   (if (== (is-non-recoverable-error $error) true)
       false
       (let $counts (collapse (match &recovery_space (TaskRetryCount $plan_id $task_id $c) $c))
         (let $curr (if (== $counts ()) 0 (car-atom $counts))
           (if (< $curr (max-task-retries))
               true
               false)))))

;; Increment task retry counter
(= (record-task-retry $plan_id $task_id)
   (let $counts (collapse (match &recovery_space (TaskRetryCount $plan_id $task_id $c) $c))
     (let $curr (if (== $counts ()) 0 (car-atom $counts))
       (let $next (+ $curr 1)
         (progn
           (if (not (== $counts ()))
               (remove-atom &recovery_space (TaskRetryCount $plan_id $task_id $curr))
               ())
           (add-atom &recovery_space (TaskRetryCount $plan_id $task_id $next))
           (plan-history-record $plan_id $task_id task_retry (string_concat "Retry attempt " (repr $next)))
           (TaskRetryRecorded $plan_id $task_id $next))))))

;; Check if goal can be replanned
(= (can-replan-goal $goal_id)
   (let $counts (collapse (match &recovery_space (GoalReplanCount $goal_id $c) $c))
     (let $curr (if (== $counts ()) 0 (car-atom $counts))
       (if (< $curr (max-goal-replans))
           true
           false))))

;; Record a goal replanning attempt
(= (record-goal-replan $goal_id)
   (let $counts (collapse (match &recovery_space (GoalReplanCount $goal_id $c) $c))
     (let $curr (if (== $counts ()) 0 (car-atom $counts))
       (let $next (+ $curr 1)
         (progn
           (if (not (== $counts ()))
               (remove-atom &recovery_space (GoalReplanCount $goal_id $curr))
               ())
           (add-atom &recovery_space (GoalReplanCount $goal_id $next))
           (GoalReplanRecorded $goal_id $next))))))

;; Clear recovery state
(= (recovery-reset)
   (progn
     (collapse (match &recovery_space $x (remove-atom &recovery_space $x)))
     "Recovery space cleared."))
