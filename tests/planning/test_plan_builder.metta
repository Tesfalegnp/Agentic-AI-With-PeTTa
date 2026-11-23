;; =============================================================================
;; STAGE D - MILESTONE 11: Plan Builder & Parser Unit Tests
;; File: tests/planning/test_plan_builder.metta
;; =============================================================================

!(println! "=== Starting Plan Builder Unit Tests ===")

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "../../agent/goal_manager.metta")
!(import! &self "../../agent/plan_types.metta")
!(import! &self "../../agent/plan_state.metta")
!(import! &self "../../agent/plan_builder.metta")

;; Reset spaces
!(goal-clear)
!(plan-clear-all)

;; Test 1: Parse Valid Plan Proposal
!(println! "--- Test 1: Parse Valid Proposal ---")
!(let $prop_str "(plan-proposal \"Text Analysis Report\"
                   ((task t1 tool word_counter (\"sample text\") ())
                    (task t2 tool text_analyzer (\"sample text\") (t1))))"
   (let $res1 (parse-plan-proposal $prop_str)
     (case $res1
       (((PlanProposalParsed (plan-proposal $desc $tasks))
         (progn
           (test $desc "Text Analysis Report")
           (test (length $tasks) 2)
           (println! "Test 1 PASSED: Proposal parsed successfully.")))
        ($_ (test "expected PlanProposalParsed" "failed"))))))

;; Test 2: Parse Markdown-Wrapped Plan Proposal
!(println! "--- Test 2: Parse Markdown-Wrapped Proposal ---")
!(let $wrapped_str "Here is the plan proposal:\n```lisp\n(plan-proposal \"Math Task\" ((task t1 tool calculator (\"50 * 2\") ())))\n```\nDone."
   (let $res2 (parse-plan-proposal $wrapped_str)
     (case $res2
       (((PlanProposalParsed (plan-proposal $desc $tasks))
         (progn
           (test $desc "Math Task")
           (test (length $tasks) 1)
           (println! "Test 2 PASSED: Markdown-wrapped proposal cleaned and parsed.")))
        ($_ (test "expected PlanProposalParsed" "failed"))))))

;; Test 3: Reject Empty and Malformed Proposals
!(println! "--- Test 3: Reject Malformed Proposals ---")
!(let $res_empty (parse-plan-proposal "")
   (case $res_empty
     (((PlanProposalError $err)
       (println! "Test 3a PASSED: Empty proposal string rejected."))
      ($_ (test "expected PlanProposalError" "failed")))))

!(let $res_bad (parse-plan-proposal "(invalid-syntax foo bar)")
   (case $res_bad
     (((PlanProposalError $err)
       (println! "Test 3b PASSED: Non-conforming syntax rejected."))
      ($_ (test "expected PlanProposalError" "failed")))))

;; Test 4: Build Plan into State from Proposal
!(println! "--- Test 4: Build Plan from Proposal into State ---")
!(let* (($g_res (goal-create "Analyze text and compute word count."))
        ($gid   (case $g_res (((GoalCreated $id) $id))))
        ($prop  (plan-proposal "Execution Plan"
                  ((task t1 tool word_counter ("hello world") ())
                   (task t2 tool text_analyzer ("hello world") (t1)))))
        ($b_res (build-plan-from-proposal $gid $prop)))
   (case $b_res
     (((PlanBuilt "plan_1")
       (let $tasks (plan-get-tasks "plan_1")
         (progn
           (test (length $tasks) 2)
           (println! "Test 4 PASSED: Plan and 2 tasks built into state successfully."))))
      ($_ (test "expected PlanBuilt plan_1" "failed")))))

!(println! "=== ALL PLAN BUILDER UNIT TESTS PASSED ===")
