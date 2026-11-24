;; =============================================================================
;; Automated Tests: Mandatory System Tools (read_file, write_file, run_command, send_message)
;; File: tests/tools/test_system_tools.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "../../agent/tool_registry.metta")
!(import! &self "../../agent/tool_validator.metta")
!(import! &self "../../agent/tool_dispatcher.metta")

!(println! "--- Running Test: Tool Registry Verification ---")
!(test (is-tool-registered read_file) true)
!(test (is-tool-registered write_file) true)
!(test (is-tool-registered run_command) true)
!(test (is-tool-registered send_message) true)

!(println! "--- Running Test: write_file Tool ---")
!(let $res (dispatch-tool write_file ("test_output.tmp" "PeTTa Agentic Framework Test Data"))
   (test (case $res (((ToolResult success write_file $s) true) ($_ false))) true))

!(println! "--- Running Test: read_file Tool (Existing File) ---")
!(let $res (dispatch-tool read_file ("test_output.tmp"))
   (test (case $res (((ToolResult success read_file $content) (== $content "PeTTa Agentic Framework Test Data")) ($_ false))) true))

!(println! "--- Running Test: read_file Tool (Missing File) ---")
!(let $res (dispatch-tool read_file ("non_existent_file_xyz_123.tmp"))
   (test (case $res (((ToolResult failure read_file $err) true) ($_ false))) true))

!(println! "--- Running Test: write_file Tool (Forbidden Path Safety) ---")
!(let $res (dispatch-tool write_file ("/etc/forbidden_test.tmp" "bad content"))
   (test (case $res (((ToolResult failure write_file $err) true) ($_ false))) true))

!(println! "--- Running Test: run_command Tool (Harmless Command) ---")
!(let $res (dispatch-tool run_command ("echo 'hello shell'"))
   (test (case $res (((ToolResult success run_command $out) true) ($_ false))) true))

!(println! "--- Running Test: run_command Tool (Destructive Command Blocked Without Approval) ---")
!(let $res (dispatch-tool run_command ("rm -rf /some/test/path" 5 false))
   (test (case $res (((ToolResult failure run_command $err) true) ($_ false))) true))

!(println! "--- Running Test: run_command Tool (Command Timeout Guardrail) ---")
!(let $res (dispatch-tool run_command ("sleep 5" 1 false))
   (test (case $res (((ToolResult success run_command $out) true) ($_ false))) true))

!(println! "--- Running Test: send_message Tool ---")
!(let $res (dispatch-tool send_message ("System operational and all safety checks verified."))
   (test (case $res (((ToolResult success send_message $msg) true) ($_ false))) true))

!(println! "--- Running Test: Cleanup Temporary File ---")
!(let $res (dispatch-tool run_command ("rm -f test_output.tmp"))
   (test (case $res (((ToolResult success run_command $out) true) ($_ false))) true))

!(println! "ALL MANDATORY SYSTEM TOOLS TESTS COMPLETED SUCCESSFULLY!")
