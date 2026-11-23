;; =============================================================================
;; STAGE C - MILESTONE 8: Skill Workflow & Context Unit Test Suite
;; File: tests/skills/test_skill_workflow.metta
;; =============================================================================

!(println! "=== Starting Skill Workflow Unit Tests ===")

!(import! &self "../../agent/skill_context.metta")
!(import! &self "../../agent/skill_workflow.metta")

;; Test 1: Context initialization and storage
!(println! "--- Test 1: Context Storage and Retrieval ---")
!(test (context-init) "Context initialized.")
!(test (context-store step1 42) (Stored step1))
!(test (context-get step1) 42)

;; Test 2: Missing step reference handling
!(println! "--- Test 2: Missing Reference Handling ---")
!(test (context-get missing_step) (Error missing_step_result missing_step))

;; Test 3: Context clearance and isolation
!(println! "--- Test 3: Context Clearance ---")
!(test (context-clear) "Context cleared.")
!(test (context-get step1) (Error missing_step_result step1))

;; Test 4: Workflow step execution
!(println! "--- Test 4: Workflow Step Execution ---")
!(test (workflow-execute-step (tool_step s1 calculator ("50 * 2")))
       (StepResult success s1 100))
!(test (context-get s1) 100)

;; Test 5: Max steps boundary
!(println! "--- Test 5: Max Workflow Steps ---")
!(test (max-workflow-steps) 10)

!(println! "=== SKILL WORKFLOW UNIT TESTS COMPLETED SUCCESSFULLY ===")
