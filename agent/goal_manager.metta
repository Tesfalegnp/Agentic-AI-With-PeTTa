;; =============================================================================
;; STAGE D - MILESTONE 11: Goal Manager Subsystem
;; Module: agent/goal_manager.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "plan_types.metta")
!(import! &self "plan_state.metta")

!(bind! &goal_space (new-space))

;; Counter initialization
!(add-atom &goal_space (GoalCounter 0))

;; Next Goal ID generator
(= (goal-next-id)
   (let $c_atoms (collapse (match &goal_space (GoalCounter $c) $c))
     (let $current (if (== $c_atoms ()) 0 (car-atom $c_atoms))
       (let $next (+ $current 1)
         (progn
           (remove-atom &goal_space (GoalCounter $current))
           (add-atom &goal_space (GoalCounter $next))
           (string_concat "goal_" (repr $next)))))))

;; Create a new Goal
(= (goal-create $description)
   (let* (($gid (goal-next-id))
          ($now (get_plan_timestamp)))
     (progn
       (add-atom &goal_space (Goal $gid $description active $now))
       (GoalCreated $gid))))

;; Retrieve a Goal by ID
(= (goal-get $goal_id)
   (let $found (collapse (match &goal_space (Goal $goal_id $desc $status $created_at)
                                (Goal $goal_id $desc $status $created_at)))
     (if (== $found ())
         (GoalNotFound $goal_id)
         (car-atom $found))))

;; Validate Status Transition
(= (is-valid-goal-transition $from $to)
   (case ($from $to)
     (((active completed) true)
      ((active failed) true)
      ((active cancelled) true)
      ((active blocked) true)
      ((blocked active) true)
      ((blocked failed) true)
      ((blocked cancelled) true)
      ($_ false))))

;; Update Goal Status
(= (goal-update-status $goal_id $new_status)
   (if (== (is-valid-goal-status $new_status) false)
       (GoalTransitionError $goal_id unknown $new_status "Invalid goal status symbol.")
       (let $existing (collapse (match &goal_space (Goal $goal_id $desc $status $created_at)
                                       (Goal $goal_id $desc $status $created_at)))
         (if (== $existing ())
             (GoalNotFound $goal_id)
             (let (Goal $goal_id $desc $current_status $created_at) (car-atom $existing)
               (if (== (is-valid-goal-transition $current_status $new_status) true)
                   (progn
                     (remove-atom &goal_space (Goal $goal_id $desc $current_status $created_at))
                     (add-atom &goal_space (Goal $goal_id $desc $new_status $created_at))
                     (GoalStatusUpdated $goal_id $new_status))
                   (GoalTransitionError $goal_id $current_status $new_status "Illegal status transition.")))))))

;; List active goals
(= (goal-list-active)
   (collapse (match &goal_space (Goal $gid $desc active $created)
                    (Goal $gid $desc active $created))))

;; List all goals
(= (goal-list-all)
   (collapse (match &goal_space (Goal $gid $desc $status $created)
                    (Goal $gid $desc $status $created))))

;; Clear goal space (for tests and session reset)
(= (goal-clear)
   (progn
     (collapse (match &goal_space $x (remove-atom &goal_space $x)))
     (add-atom &goal_space (GoalCounter 0))
     "Goal space cleared."))
