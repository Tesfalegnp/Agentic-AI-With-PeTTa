;; =============================================================================
;; Automated Tests: Web Search Tool Integration in PeTTa
;; File: tests/tools/test_web_search_tool.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "../../agent/tool_registry.metta")
!(import! &self "../../agent/tool_validator.metta")
!(import! &self "../../agent/tool_dispatcher.metta")

!(println! "--- Running Test: web_search Registration Verification ---")
!(test (is-tool-registered web_search) true)

!(println! "--- Running Test: web_search Argument Validation ---")
!(let $v1 (validate-tool-call web_search ("query"))
   (test (case $v1 (((ToolValidationSuccess web_search $a) true) ($_ false))) true))

!(let $v2 (validate-tool-call web_search ("query" 3))
   (test (case $v2 (((ToolValidationSuccess web_search $a) true) ($_ false))) true))

!(let $v3 (validate-tool-call web_search ())
   (test (case $v3 (((ToolValidationFailure web_search $r) true) ($_ false))) true))

!(println! "--- Running Test: web_search Tool Dispatch (Offline / Fallback Safe) ---")
!(let $res (dispatch-tool web_search ("PeTTa Artificial Intelligence" 2))
   (test (case $res (((ToolResult success web_search $obs) (if (== $obs "") false true)) ($_ false))) true))

!(println! "WEB SEARCH TOOL VERIFICATION PASSED! ✅")
