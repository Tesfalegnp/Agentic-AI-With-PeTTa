;; =============================================================================
;; Evaluator Scenario B: Multi-Step Dataset Computation, Aggregation & Verification
;; File: tests/integration/test_scenario_b_data_calc.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "../../agent/tool_registry.metta")
!(import! &self "../../agent/tool_validator.metta")
!(import! &self "../../agent/tool_dispatcher.metta")
!(import! &self "../../agent/state.metta")

!(println! "--- Step 1: Writing Test Dataset to Disk ---")
!(let $w (dispatch-tool write_file ("dataset.csv" "student,score\nalice,85\nbob,90\ncharlie,95"))
   (test (case $w (((ToolResult success write_file $s) true) ($_ false))) true))

!(println! "--- Step 2: Reading Dataset via read_file ---")
!(let $r (dispatch-tool read_file ("dataset.csv"))
   (test (case $r (((ToolResult success read_file $c) (if (== $c "") false true)) ($_ false))) true))

!(println! "--- Step 3: Computing Total and Average Scores ---")
;; Total: 85 + 90 + 95 = 270
!(let $t (dispatch-tool calculator ("85 + 90 + 95"))
   (test (case $t (((ToolResult success calculator 270) true) ($_ false))) true))

;; Average: 270 / 3 = 90
!(let $avg (dispatch-tool calculator ("270 / 3"))
   (test (case $avg (((ToolResult success calculator 90) true) ($_ false))) true))

!(println! "--- Step 4: Cleanup Dataset File ---")
!(let $del (dispatch-tool run_command ("rm -f dataset.csv"))
   (test (case $del (((ToolResult success run_command $o) true) ($_ false))) true))

!(println! "SCENARIO B (DATASET COMPUTATION & REPORT) PASSED SUCCESSFULLY! ✅")
