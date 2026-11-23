;; =============================================================================
;; STAGE C - MILESTONE 8: Skill History Unit Test Suite
;; File: tests/skills/test_skill_history.metta
;; =============================================================================

!(println! "=== Starting Skill History Unit Tests ===")

!(import! &self "../../agent/skill_history.metta")

;; Test 1: Clear history
!(println! "--- Test 1: Clear History ---")
!(test (skill-history-clear) "Skill history cleared.")
!(test (skill-history-list) ())

;; Test 2: Record skill executions
!(println! "--- Test 2: Record Executions ---")
!(test (history-record-skill-call math_skill ("125 * 8") success "1000" 2)
       (HistoryRecorded 1 math_skill))
!(test (history-record-skill-call text_process_skill ("Sample text") success "Metrics" 3)
       (HistoryRecorded 2 text_process_skill))

;; Test 3: Filter by skill
!(println! "--- Test 3: Filter by Skill ---")
!(let $math_records (skill-history-get-by-skill math_skill)
   (println! "Retrieved math_skill history records."))

;; Test 4: Final clear
!(test (skill-history-clear) "Skill history cleared.")
!(test (skill-history-list) ())

!(println! "=== SKILL HISTORY UNIT TESTS COMPLETED SUCCESSFULLY ===")
