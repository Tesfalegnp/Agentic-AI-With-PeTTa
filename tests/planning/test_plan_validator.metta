;; =============================================================================
;; STAGE D - MILESTONE 11: Plan Validator Unit Tests
;; File: tests/planning/test_plan_validator.metta
;; =============================================================================

!(println! "=== Starting Plan Validator Unit Tests ===")

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import_prolog_functions_from_file "agent/memory_io.pl" (sub_string_match))
!(import! &self "../../agent/goal_manager.metta")
!(import! &self "../../agent/plan_types.metta")
!(import! &self "../../agent/plan_state.metta")
!(import! &self "../../agent/plan_validator.metta")
!(import! &self "../../agent/tool_registry.metta")
!(import! &self "../../agent/skill_registry.metta")

;; Reset spaces
!(goal-clear)
!(plan-clear-all)

;; Test 1: Valid Plan Accepted
!(println! "--- Test 1: Valid Plan Accepted ---")
!(let* (($g (goal-create "Test valid plan."))
        ($gid (case $g (((GoalCreated $id) $id))))
        ($p (plan-create $gid "Valid Plan"))
        ($pid (case $p (((PlanCreated $id) $id)))))
   (progn
     (plan-add-task $pid t1 "Count words" tool word_counter ("hello world") ())
     (plan-add-task $pid t2 "Analyze text" tool text_analyzer ("hello world") (t1))
     (let $res1 (validate-plan $pid)
       (case $res1
         (((PlanValidationSuccess $pid)
           (println! "Test 1 PASSED: Valid plan accepted."))
          ($_ (test "expected PlanValidationSuccess" "failed")))))))

;; Test 2: Unknown Tool Rejected
!(println! "--- Test 2: Unknown Tool Rejected ---")
!(let* (($p (plan-create "goal_1" "Unknown Tool Plan"))
        ($pid (case $p (((PlanCreated $id) $id)))))
   (progn
     (plan-add-task $pid t1 "Bad tool" tool unknown_magic_tool ("arg") ())
     (let $res2 (validate-plan $pid)
       (case $res2
         (((PlanValidationFailure $pid $reason)
           (progn
             (test (sub_string_match $reason "Unregistered tool") true)
             (println! "Test 2 PASSED: Unknown tool rejected.")))
          ($_ (test "expected PlanValidationFailure" "failed")))))))

;; Test 3: Disabled Tool Rejected
!(println! "--- Test 3: Disabled Tool Rejected ---")
!(disable-tool calculator)
!(let* (($p (plan-create "goal_1" "Disabled Tool Plan"))
        ($pid (case $p (((PlanCreated $id) $id)))))
   (progn
     (plan-add-task $pid t1 "Calc" tool calculator ("5 * 5") ())
     (let $res3 (validate-plan $pid)
       (case $res3
         (((PlanValidationFailure $pid $reason)
           (progn
             (test (sub_string_match $reason "Tool is disabled") true)
             (enable-tool calculator)
             (println! "Test 3 PASSED: Disabled tool rejected.")))
          ($_ (test "expected PlanValidationFailure" "failed")))))))

;; Test 4: Missing Dependency Rejected
!(println! "--- Test 4: Missing Dependency Rejected ---")
!(let* (($p (plan-create "goal_1" "Missing Dep Plan"))
        ($pid (case $p (((PlanCreated $id) $id)))))
   (progn
     (plan-add-task $pid t1 "Step 1" tool word_counter ("test") (non_existent_task))
     (let $res4 (validate-plan $pid)
       (case $res4
         (((PlanValidationFailure $pid $reason)
           (progn
             (test (sub_string_match $reason "Missing dependency reference") true)
             (println! "Test 4 PASSED: Missing dependency reference rejected.")))
          ($_ (test "expected PlanValidationFailure" "failed")))))))

;; Test 5: Circular Dependency Rejected
!(println! "--- Test 5: Circular Dependency Rejected ---")
!(let* (($p (plan-create "goal_1" "Cycle Plan"))
        ($pid (case $p (((PlanCreated $id) $id)))))
   (progn
     (plan-add-task $pid t1 "Step 1" tool word_counter ("test") (t2))
     (plan-add-task $pid t2 "Step 2" tool word_counter ("test") (t1))
     (let $res5 (validate-plan $pid)
       (case $res5
         (((PlanValidationFailure $pid $reason)
           (progn
             (test (sub_string_match $reason "Circular dependency detected") true)
             (println! "Test 5 PASSED: Circular dependency rejected.")))
          ($_ (test "expected PlanValidationFailure" "failed")))))))

;; Test 6: Self-Dependency Rejected
!(println! "--- Test 6: Self-Dependency Rejected ---")
!(let* (($p (plan-create "goal_1" "Self Dep Plan"))
        ($pid (case $p (((PlanCreated $id) $id)))))
   (progn
     (plan-add-task $pid t1 "Step 1" tool word_counter ("test") (t1))
     (let $res6 (validate-plan $pid)
       (case $res6
         (((PlanValidationFailure $pid $reason)
           (progn
             (test (sub_string_match $reason "Self-dependency detected") true)
             (println! "Test 6 PASSED: Self-dependency rejected.")))
          ($_ (test "expected PlanValidationFailure" "failed")))))))

;; Test 7: Invalid Arguments Rejected
!(println! "--- Test 7: Invalid Tool Arguments Rejected ---")
!(let* (($p (plan-create "goal_1" "Bad Args Plan"))
        ($pid (case $p (((PlanCreated $id) $id)))))
   (progn
     ;; calculator expects string containing mathematical expression, not empty ()
     (plan-add-task $pid t1 "Bad calc" tool calculator () ())
     (let $res7 (validate-plan $pid)
       (case $res7
         (((PlanValidationFailure $pid $reason)
           (println! "Test 7 PASSED: Invalid tool arguments rejected."))
          ($_ (test "expected PlanValidationFailure" "failed")))))))

!(println! "=== ALL PLAN VALIDATOR UNIT TESTS PASSED ===")
