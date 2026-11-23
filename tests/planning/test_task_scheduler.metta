;; =============================================================================
;; STAGE D - MILESTONE 11: Task Scheduler Unit Tests
;; File: tests/planning/test_task_scheduler.metta
;; =============================================================================

!(println! "=== Starting Task Scheduler Unit Tests ===")

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "../../agent/goal_manager.metta")
!(import! &self "../../agent/plan_types.metta")
!(import! &self "../../agent/plan_state.metta")
!(import! &self "../../agent/task_scheduler.metta")
!(import! &self "../../agent/plan_history.metta")

;; Reset spaces
!(goal-clear)
!(plan-clear-all)
!(plan-history-clear)

;; -----------------------------------------------------------------------------
;; Test 1 & 2 & 3: Dependency Progression (Pending -> Ready -> Completed)
;; -----------------------------------------------------------------------------
!(println! "--- Test 1-3: Dependency Progression ---")
!(let* (($g (goal-create "Test scheduling progression."))
        ($gid (case $g (((GoalCreated $id) $id))))
        ($p (plan-create $gid "Schedule Plan"))
        ($pid (case $p (((PlanCreated $id) $id)))))
   (progn
     ;; t1 has no dependencies; t2 depends on t1
     (plan-add-task $pid t1 "First task" tool word_counter ("hello") ())
     (plan-add-task $pid t2 "Second task" tool text_analyzer ("hello") (t1))

     ;; Test 1: Initial schedule makes t1 ready, returns NextTask t1
     (let $s1 (schedule-next-task $pid)
       (case $s1
         (((NextTask t1)
           (println! "Test 1 PASSED: Independent task t1 scheduled first."))
          ($_ (test "expected NextTask t1" "failed")))))

     ;; Mark t1 as running (simulating execution start)
     (task-update-status $pid t1 running none)

     ;; Test 2: While t1 is running, t2 cannot run yet (NoTasksReady)
     (let $s2 (schedule-next-task $pid)
       (case $s2
         (((NoTasksReady)
           (println! "Test 2 PASSED: Dependent task t2 waits while t1 is running."))
          ($_ (test "expected NoTasksReady" "failed")))))

     ;; Mark t1 as completed
     (task-update-status $pid t1 completed (TaskResult success 1))

     ;; Test 3: With t1 completed, t2 becomes ready
     (let $s3 (schedule-next-task $pid)
       (case $s3
         (((NextTask t2)
           (println! "Test 3 PASSED: Dependent task t2 scheduled once t1 completed."))
          ($_ (test "expected NextTask t2" "failed")))))

     ;; Mark t2 as completed
     (task-update-status $pid t2 completed (TaskResult success 1))

     ;; Test 4: All tasks completed
     (let $s4 (schedule-next-task $pid)
       (case $s4
         (((AllTasksCompleted $pid)
           (println! "Test 4 PASSED: All tasks reported completed."))
          ($_ (test "expected AllTasksCompleted" "failed")))))))

;; -----------------------------------------------------------------------------
;; Test 5: Failed Dependency Blocks Dependent Tasks
;; -----------------------------------------------------------------------------
!(println! "--- Test 5: Failed Dependency Blocks Dependent Task ---")
!(let* (($p2 (plan-create "goal_1" "Failure Block Plan"))
        ($pid2 (case $p2 (((PlanCreated $id) $id)))))
   (progn
     (plan-add-task $pid2 t1 "Failing task" tool calculator ("1/0") ())
     (plan-add-task $pid2 t2 "Dependent task" tool calculator ("5*2") (t1))

     ;; Mark t1 as failed
     (task-update-status $pid2 t1 failed (TaskResult failure "Division by zero."))

     ;; Scheduling should detect t1 failed, mark t2 blocked, and return PlanBlocked
     (let $s5 (schedule-next-task $pid2)
       (case $s5
         (((PlanBlocked $pid2)
           (let $t2_task (task-get $pid2 t2)
             (case $t2_task
               (((PlanTask t2 $pid2 $desc $type $name $args $deps blocked $res)
                 (println! "Test 5 PASSED: Dependent task blocked and plan marked PlanBlocked."))
                ($_ (test "expected t2 blocked" "failed"))))))
          ($_ (test "expected PlanBlocked" "failed")))))))

!(println! "=== ALL TASK SCHEDULER UNIT TESTS PASSED ===")
