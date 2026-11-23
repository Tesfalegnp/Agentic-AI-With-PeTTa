;; =============================================================================
;; STAGE D - MILESTONE 11: Planning Agent Loop & Decision Unit Tests
;; File: tests/planning/test_planning_agent_loop.metta
;; =============================================================================

!(println! "=== Starting Planning Agent Loop Unit Tests ===")

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import_prolog_functions_from_file "agent/memory_io.pl" (sub_string_match))
!(import! &self "../../agent/loop.metta")
!(import! &self "../../agent/goal_planner.metta")
!(import! &self "../../agent/memory_core.metta")
!(import! &self "../../agent/memory_store.metta")
!(import! &self "../../agent/state.metta")

;; Reset stores and history
!(goal-clear)
!(plan-clear-all)
!(plan-history-clear)
!(memory-clear-all)
!(state-clear)

;; -----------------------------------------------------------------------------
;; Test 1: Deterministic Planning Criteria (Explainable & Testable)
;; -----------------------------------------------------------------------------
!(println! "--- Test 1: Planning Criteria Decisions ---")
;; Factual query -> false (direct answer)
!(let $d1 (should-plan-request "What is the capital of Japan?")
   (progn
     (test $d1 false)
     (println! "Test 1a PASSED: Factual query does not trigger planning.")))

;; Single tool calculation -> false
!(let $d2 (should-plan-request "Calculate 125 * 8.")
   (progn
     (test $d2 false)
     (println! "Test 1b PASSED: Single tool calculation does not trigger planning.")))

;; Multi-step request -> true
!(let $d3 (should-plan-request "Analyze this text, calculate its word count, compare the results, and prepare a concise summary.")
   (progn
     (test $d3 true)
     (println! "Test 1c PASSED: Multi-step request correctly triggers planning.")))

;; Pipeline with 'and then' -> true
!(let $d4 (should-plan-request "Count words in this document and then analyze the text.")
   (progn
     (test $d4 true)
     (println! "Test 1d PASSED: Conjunction 'and then' correctly triggers planning.")))

;; -----------------------------------------------------------------------------
;; Test 2: Memory-Aware Planning Prompt Assembly
;; -----------------------------------------------------------------------------
!(println! "--- Test 2: Memory-Aware Planning Prompt ---")
!(memory-store-with-priority fact "The codename is Project Chimera." 5)

!(let $plan_prompt (build-planning-prompt "Analyze text and count words for Project Chimera.")
   (progn
     (test (sub_string_match $plan_prompt "Project Chimera") true)
     (test (sub_string_match $plan_prompt "AVAILABLE TOOLS") true)
     (test (sub_string_match $plan_prompt "AVAILABLE SKILLS") true)
     (test (sub_string_match $plan_prompt "(plan-proposal") true)
     (println! "Test 2 PASSED: Planning prompt includes relevant memory and capabilities.")))

;; -----------------------------------------------------------------------------
;; Test 3: Plan Proposal Execution & Verification Cycle
;; -----------------------------------------------------------------------------
!(println! "--- Test 3: Plan Proposal End-to-End Execution & Verification ---")
!(let* (($g_res (goal-create "Execute multi-step text analysis."))
        ($gid   (case $g_res (((GoalCreated $id) $id))))
        ($prop  (plan-proposal "Multi-Step Text Processing"
                  ((task t1 tool word_counter ("Autonomous Agentic Intelligence") ())
                   (task t2 tool text_analyzer ("Autonomous Agentic Intelligence") (t1)))))
        ($b_res (build-plan-from-proposal $gid $prop))
        ($pid   (case $b_res (((PlanBuilt $id) $id))))
        ($v_res (validate-plan $pid))
        ($e_res (execute-plan $pid))
        ($final_verif (verify-plan-completion $gid $pid)))
   (progn
     (test (case $v_res (((PlanValidationSuccess $pid) true) ($_ false))) true)
     (test (case $e_res (((PlanExecutionSuccess $pid) true) ($_ false))) true)
     (test (case $final_verif (((GoalVerified $gid $pid) true) ($_ false))) true)
     (let $tasks (plan-get-tasks $pid)
       (let $summary (format-task-summary $tasks)
         (progn
           (test (sub_string_match $summary "Task t1 (word_counter): 3") true)
           (println! "Test 3 PASSED: Proposal built, validated, executed, verified, and summarized successfully."))))))

!(println! "=== ALL PLANNING AGENT LOOP UNIT TESTS PASSED ===")
