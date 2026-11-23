;; =============================================================================
;; STAGE D - MILESTONE 11: Goal Manager Unit Tests
;; File: tests/planning/test_goal_manager.metta
;; =============================================================================

!(println! "=== Starting Goal Manager Unit Tests ===")

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "../../agent/goal_manager.metta")

;; Reset goal space
!(goal-clear)

;; Test 1: Goal Creation
!(println! "--- Test 1: Goal Creation ---")
!(let $res1 (goal-create "Analyze financial report and generate summary.")
   (case $res1
     (((GoalCreated "goal_1")
       (println! "Test 1 PASSED: Goal created with ID goal_1."))
      ($_ (test "expected GoalCreated goal_1" "failed")))))

;; Test 2: Goal Retrieval
!(println! "--- Test 2: Goal Retrieval ---")
!(let $g1 (goal-get "goal_1")
   (case $g1
     (((Goal "goal_1" $desc active $ts)
       (progn
         (test $desc "Analyze financial report and generate summary.")
         (println! "Test 2 PASSED: Goal retrieved successfully with active status.")))
      ($_ (test "expected Goal goal_1 active" "failed")))))

;; Non-existent goal retrieval
!(let $g_none (goal-get "goal_999")
   (test $g_none (GoalNotFound "goal_999")))

;; Test 3: Valid Goal Status Transitions
!(println! "--- Test 3: Valid Goal Status Transitions ---")
;; active -> blocked
!(let $t1 (goal-update-status "goal_1" blocked)
   (test $t1 (GoalStatusUpdated "goal_1" blocked)))

;; blocked -> active
!(let $t2 (goal-update-status "goal_1" active)
   (test $t2 (GoalStatusUpdated "goal_1" active)))

;; active -> completed
!(let $t3 (goal-update-status "goal_1" completed)
   (test $t3 (GoalStatusUpdated "goal_1" completed)))

;; Test 4: Invalid Goal Status Transitions
!(println! "--- Test 4: Invalid Goal Status Transitions ---")
;; Cannot transition from completed (terminal state)
!(let $t_bad (goal-update-status "goal_1" active)
   (case $t_bad
     (((GoalTransitionError "goal_1" completed active $msg)
       (println! "Test 4a PASSED: Transition from terminal completed state rejected."))
      ($_ (test "expected GoalTransitionError" "failed")))))

;; Invalid status symbol
!(let $t_inv (goal-update-status "goal_1" nonexistent_status)
   (case $t_inv
     (((GoalTransitionError "goal_1" unknown nonexistent_status $msg)
       (println! "Test 4b PASSED: Invalid status symbol rejected."))
      ($_ (test "expected GoalTransitionError" "failed")))))

;; Test 5: Goal Listing and Reset
!(println! "--- Test 5: Goal Listing and Reset ---")
!(let $_g2 (goal-create "Second test goal.")
   (println! "Created second goal."))

!(let $active_list (goal-list-active)
   (progn
     (test (length $active_list) 1)
     (println! "Test 5a PASSED: Only active goals returned.")))

!(goal-clear)
!(let $all_after (goal-list-all)
   (progn
     (test (length $all_after) 0)
     (println! "Test 5b PASSED: Goal space cleared cleanly.")))

!(println! "=== ALL GOAL MANAGER UNIT TESTS PASSED ===")
