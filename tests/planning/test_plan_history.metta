;; =============================================================================
;; STAGE D - MILESTONE 11: Plan History Unit Tests
;; File: tests/planning/test_plan_history.metta
;; =============================================================================

!(println! "=== Starting Plan History Unit Tests ===")

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "../../agent/plan_history.metta")

;; Reset history space
!(plan-history-clear)

;; Test 1: Record Planning Audit Events
!(println! "--- Test 1: Record Audit Events ---")
!(let $rec1 (plan-history-record "plan_1" none plan_created "Plan initialized.")
   (test $rec1 (PlanHistoryLogged "plan_1" none plan_created)))

!(let $rec2 (plan-history-record "plan_1" t1 task_started "Task t1 execution begun.")
   (test $rec2 (PlanHistoryLogged "plan_1" t1 task_started)))

!(let $rec3 (plan-history-record "plan_1" t1 task_completed "Result: 100")
   (test $rec3 (PlanHistoryLogged "plan_1" t1 task_completed)))

!(let $rec4 (plan-history-record "plan_1" none goal_verified "Goal verified successfully.")
   (test $rec4 (PlanHistoryLogged "plan_1" none goal_verified)))

;; Test 2: List Plan History Entries
!(println! "--- Test 2: List History Entries ---")
!(let $entries (plan-history-list)
   (progn
     (test (length $entries) 4)
     (println! "Test 2 PASSED: All 4 audit events retrieved.")))

;; Test 3: Clear Plan History
!(println! "--- Test 3: Clear Plan History ---")
!(plan-history-clear)
!(let $after (plan-history-list)
   (progn
     (test (length $after) 0)
     (println! "Test 3 PASSED: Plan history cleared cleanly.")))

!(println! "=== ALL PLAN HISTORY UNIT TESTS PASSED ===")
