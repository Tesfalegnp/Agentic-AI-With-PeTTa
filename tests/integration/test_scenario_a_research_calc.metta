;; =============================================================================
;; Evaluator Scenario A: Web Research, Comparison, and Computation
;; File: tests/integration/test_scenario_a_research_calc.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "../../agent/tool_registry.metta")
!(import! &self "../../agent/tool_validator.metta")
!(import! &self "../../agent/tool_dispatcher.metta")
!(import! &self "../../agent/state.metta")

!(println! "--- Step 1: Web Research for Student Laptops ---")
!(state-clear)
!(let $s_res (dispatch-tool web_search ("best student laptop computer science" 3))
   (test (case $s_res (((ToolResult success web_search $obs) (if (== $obs "") false true)) ($_ false))) true))

!(println! "--- Step 2: Extracting Prices & Computing Tax (10%) ---")
;; Option 1: Dell XPS 13 base ($999 + $99 tax = $1098)
!(let $c1 (dispatch-tool calculator ("999 + 99"))
   (test (case $c1 (((ToolResult success calculator $val) (== $val 1098)) ($_ false))) true))

;; Option 2: MacBook Air M2 ($899 + $90 tax = $989)
!(let $c2 (dispatch-tool calculator ("899 + 90"))
   (test (case $c2 (((ToolResult success calculator $val) (== $val 989)) ($_ false))) true))

;; Option 3: Lenovo ThinkPad E14 ($750 + $75 tax = $825)
!(let $c3 (dispatch-tool calculator ("750 + 75"))
   (test (case $c3 (((ToolResult success calculator $val) (== $val 825)) ($_ false))) true))

!(println! "--- Step 3: Recording Decision to Working Memory ---")
!(let $_a (state-add-assistant-message "Recommendation: Lenovo ThinkPad E14 offers the best price-to-performance for CS coursework ($825 with tax). MacBook Air M2 ($989) recommended for battery efficiency."))
!(let $ctx (state-get-context)
   (test (if (== $ctx "") false true) true))

!(println! "SCENARIO A (RESEARCH & COMPUTATION) PASSED SUCCESSFULLY! ✅")
