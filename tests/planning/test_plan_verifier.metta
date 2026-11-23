;; =============================================================================
;; STAGE D - MILESTONE 11: Plan Verifier Unit Tests
;; File: tests/planning/test_plan_verifier.metta
;; =============================================================================

!(println! "=== Starting Plan Verifier Unit Tests ===")

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "../../agent/goal_manager.metta")
!(import! &self "../../agent/plan_types.metta")
!(import! &self "../../agent/plan_state.metta")
!(import! &self "../../agent/plan_history.metta")
!(import! &self "../../agent/plan_verifier.metta")

;; Reset spaces
!(goal-clear)
!(plan-clear-all)
!(plan-history-clear)

;; -----------------------------------------------------------------------------
;; Test 1: Valid Completed Plan Completes Goal
;; -----------------------------------------------------------------------------
!(println! "--- Test 1: Successful Plan Verification ---")
!(let* (($g (goal-create "Complete all mathematical calculations."))
        ($gid (case $g (((GoalCreated $id) $id))))
        ($p (plan-create $gid "Calculation Plan"))
        ($pid (case $p (((PlanCreated $id) $id)))))
   (progn
     (plan-add-task $pid t1 "Calculate product" tool calculator ("5 * 5") ())
     (task-update-status $pid t1 completed (TaskResult success 25))
     (plan-update-status $pid completed)
     (let $v1 (verify-plan-completion $gid $pid)
       (case $v1
         (((GoalVerified $gid $pid)
           (let $g_st (goal-get $gid)
             (case $g_st
               (((Goal $gid $desc completed $ts)
                 (println! "Test 1 PASSED: Plan verified and goal status updated to completed."))
                ($_ (test "expected goal completed" "failed"))))))
          ($_ (test "expected GoalVerified" "failed")))))))

;; -----------------------------------------------------------------------------
;; Test 2: Incomplete Plan Fails Verification
;; -----------------------------------------------------------------------------
!(println! "--- Test 2: Incomplete Plan Fails Verification ---")
!(let* (($g2 (goal-create "Incomplete work goal."))
        ($gid2 (case $g2 (((GoalCreated $id) $id))))
        ($p2 (plan-create $gid2 "Draft Plan"))
        ($pid2 (case $p2 (((PlanCreated $id) $id)))))
   (progn
     (plan-add-task $pid2 t1 "Task still pending" tool calculator ("1+1") ())
     ;; Plan is still in draft state
     (let $v2 (verify-plan-completion $gid2 $pid2)
       (case $v2
         (((GoalIncomplete $gid2 $reason)
           (println! "Test 2 PASSED: Non-completed plan correctly fails verification."))
          ($_ (test "expected GoalIncomplete" "failed")))))))

;; -----------------------------------------------------------------------------
;; Test 3: Plan with Failed Task Prevents False Completion
;; -----------------------------------------------------------------------------
!(println! "--- Test 3: Failed Task Prevents Goal Completion ---")
!(let* (($g3 (goal-create "Goal with a failing step."))
        ($gid3 (case $g3 (((GoalCreated $id) $id))))
        ($p3 (plan-create $gid3 "Failed Task Plan"))
        ($pid3 (case $p3 (((PlanCreated $id) $id)))))
   (progn
     (plan-add-task $pid3 t1 "Failing task" tool calculator ("1/0") ())
     (task-update-status $pid3 t1 failed (TaskResult failure "Division by zero."))
     (plan-update-status $pid3 completed)
     (let $v3 (verify-plan-completion $gid3 $pid3)
       (case $v3
         (((GoalIncomplete $gid3 $reason)
           (println! "Test 3 PASSED: Failed task prevents goal from being marked complete."))
          ($_ (test "expected GoalIncomplete" "failed")))))))

!(println! "=== ALL PLAN VERIFIER UNIT TESTS PASSED ===")
