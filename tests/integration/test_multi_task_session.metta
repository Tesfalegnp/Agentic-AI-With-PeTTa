;; =============================================================================
;; Automated Test: Multi-Task Sequential Session Execution
;; File: tests/integration/test_multi_task_session.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "../../agent/tool_registry.metta")
!(import! &self "../../agent/tool_validator.metta")
!(import! &self "../../agent/tool_dispatcher.metta")
!(import! &self "../../agent/state.metta")
!(import! &self "../../agent/memory_core.metta")

!(println! "--- Initializing Multi-Task Session ---")
!(memory-init)
!(state-clear)

!(println! "--- Task 1: Store User Preference in Persistent Memory ---")
!(let $t1_res (memory-store preference "User prefers Python for data science")
   (test (case $t1_res (((MemoryStoreSuccess $id $cat $txt) true) ((MemoryStoreDuplicate $cat $txt) true) ($_ false))) true))

!(println! "--- Task 2: Arithmetic Calculation via Calculator Tool ---")
!(let $t2_res (dispatch-tool calculator ("150 * 4"))
   (test (case $t2_res (((ToolResult success calculator 600) true) ($_ false))) true))

!(println! "--- Task 3: Text File Writing and Verification via System Tools ---")
!(let $t3_write (dispatch-tool write_file ("session_test.txt" "Task 3 Output Data"))
   (test (case $t3_write (((ToolResult success write_file $s) true) ($_ false))) true))
!(let $t3_read (dispatch-tool read_file ("session_test.txt"))
   (test (case $t3_read (((ToolResult success read_file $c) (== $c "Task 3 Output Data")) ($_ false))) true))

!(println! "--- Task 4: Recall Memory Across Sequential Session Tasks ---")
!(let $t4_recall (memory-recall-query preference "Python")
   (test (case $t4_recall (((MemoryRecallSuccess preference $items) (if (== $items ()) false true)) ($_ false))) true))

!(println! "--- Cleanup Session Resources ---")
!(let $t5_cleanup (dispatch-tool run_command ("rm -f session_test.txt"))
   (test (case $t5_cleanup (((ToolResult success run_command $o) true) ($_ false))) true))

!(println! "MULTI-TASK SEQUENTIAL SESSION EXECUTION PASSED! ✅")
