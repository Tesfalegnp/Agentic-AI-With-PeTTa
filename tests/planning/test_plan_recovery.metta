;; =============================================================================
;; STAGE D - MILESTONE 11: Plan Recovery Unit Tests
;; File: tests/planning/test_plan_recovery.metta
;; =============================================================================

!(println! "=== Starting Plan Recovery Unit Tests ===")

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "../../agent/plan_types.metta")
!(import! &self "../../agent/plan_state.metta")
!(import! &self "../../agent/plan_history.metta")
!(import! &self "../../agent/plan_recovery.metta")

;; Reset recovery space
!(recovery-reset)

;; Test 1: Recoverable Error Retry Eligibility
!(println! "--- Test 1: Recoverable Error Eligibility ---")
!(let $can_r1 (can-retry-task "plan_1" t1 "Transient timeout or network glitch.")
   (progn
     (test $can_r1 true)
     (println! "Test 1 PASSED: Recoverable error is eligible for retry.")))

;; Test 2: Non-Recoverable Errors Rejected
!(println! "--- Test 2: Non-Recoverable Errors Rejected ---")
!(let $can_r2 (can-retry-task "plan_1" t1 "Division by zero error.")
   (progn
     (test $can_r2 false)
     (println! "Test 2a PASSED: Division by zero rejected from retry.")))

!(let $can_r3 (can-retry-task "plan_1" t1 "Tool is disabled.")
   (progn
     (test $can_r3 false)
     (println! "Test 2b PASSED: Disabled tool error rejected from retry.")))

;; Test 3: Task Retry Count Limit Enforcement
!(println! "--- Test 3: Retry Limit Enforcement ---")
!(record-task-retry "plan_1" t1)
!(let $can_r4 (can-retry-task "plan_1" t1 "Transient error.")
   (progn
     (test $can_r4 false)
     (println! "Test 3 PASSED: Task retry limit (max 1) enforced.")))

;; Test 4: Goal Replanning Limit Enforcement
!(println! "--- Test 4: Goal Replanning Limit Enforcement ---")
!(test (can-replan-goal "goal_1") true)
!(record-goal-replan "goal_1")
!(test (can-replan-goal "goal_1") false)
!(println! "Test 4 PASSED: Goal replan limit (max 1) enforced.")

!(println! "=== ALL PLAN RECOVERY UNIT TESTS PASSED ===")
