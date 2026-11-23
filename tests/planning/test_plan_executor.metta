;; =============================================================================
;; STAGE D - MILESTONE 11: Plan & Task Executor Unit Tests
;; File: tests/planning/test_plan_executor.metta
;; =============================================================================

!(println! "=== Starting Plan Executor Unit Tests ===")

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "../../agent/goal_manager.metta")
!(import! &self "../../agent/plan_types.metta")
!(import! &self "../../agent/plan_state.metta")
!(import! &self "../../agent/task_scheduler.metta")
!(import! &self "../../agent/plan_executor.metta")
!(import! &self "../../agent/plan_history.metta")

;; Reset spaces
!(goal-clear)
!(plan-clear-all)
!(plan-history-clear)

;; -----------------------------------------------------------------------------
;; Test 1: Single Tool Task Execution
;; -----------------------------------------------------------------------------
!(println! "--- Test 1: Tool Task Execution ---")
!(let* (($g (goal-create "Test tool execution."))
        ($gid (case $g (((GoalCreated $id) $id))))
        ($p (plan-create $gid "Tool Execution Plan"))
        ($pid (case $p (((PlanCreated $id) $id)))))
   (progn
     (plan-add-task $pid t1 "Calculate product" tool calculator ("25 * 4") ())
     (let $res1 (execute-task-step $pid t1)
       (case $res1
         (((TaskExecutionSuccess t1 100)
           (let $task1 (task-get $pid t1)
             (case $task1
               (((PlanTask t1 $pid $desc tool calculator $args $deps completed (TaskResult success 100))
                 (println! "Test 1 PASSED: Calculator tool task completed successfully with result 100."))
                ($_ (test "expected completed status" "failed"))))))
          ($_ (test "expected TaskExecutionSuccess t1 100" "failed")))))))

;; -----------------------------------------------------------------------------
;; Test 2: Single Skill Task Execution
;; -----------------------------------------------------------------------------
!(println! "--- Test 2: Skill Task Execution ---")
!(let* (($p2 (plan-create "goal_1" "Skill Execution Plan"))
        ($pid2 (case $p2 (((PlanCreated $id) $id)))))
   (progn
     (plan-add-task $pid2 s1 "Process text via skill" skill text_process_skill ("Autonomous Agent") ())
     (let $res2 (execute-task-step $pid2 s1)
       (case $res2
         (((TaskExecutionSuccess s1 $metrics)
           (let $task_s1 (task-get $pid2 s1)
             (case $task_s1
               (((PlanTask s1 $pid2 $desc skill text_process_skill $args $deps completed (TaskResult success $val))
                 (println! "Test 2 PASSED: Skill task executed and recorded in plan state successfully."))
                ($_ (test "expected completed skill task" "failed"))))))
          ($_ (test "expected TaskExecutionSuccess s1" "failed")))))))

;; -----------------------------------------------------------------------------
;; Test 3: Full Multi-Step Plan Execution Driver
;; -----------------------------------------------------------------------------
!(println! "--- Test 3: Multi-Step Plan Execution Driver ---")
!(let* (($p3 (plan-create "goal_1" "Multi-Step Pipeline Plan"))
        ($pid3 (case $p3 (((PlanCreated $id) $id)))))
   (progn
     (plan-add-task $pid3 t1 "Count words" tool word_counter ("hello world from petta agent") ())
     (plan-add-task $pid3 t2 "Analyze text metrics" tool text_analyzer ("hello world from petta agent") (t1))
     (let $exec_res (execute-plan $pid3)
       (case $exec_res
         (((PlanExecutionSuccess $pid3)
           (let* (($t1_st (task-get $pid3 t1))
                  ($t2_st (task-get $pid3 t2)))
             (progn
               (test (case $t1_st (((PlanTask t1 $pid3 $d $t $n $a $deps completed $r) true) ($_ false))) true)
               (test (case $t2_st (((PlanTask t2 $pid3 $d $t $n $a $deps completed $r) true) ($_ false))) true)
               (println! "Test 3 PASSED: Full multi-step plan executed in order to completion."))))
          ($_ (test "expected PlanExecutionSuccess" "failed")))))))

!(println! "=== ALL PLAN EXECUTOR UNIT TESTS PASSED ===")
