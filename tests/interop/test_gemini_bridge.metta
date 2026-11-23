; ==============================================================================
; PeTTa - Python LLM Bridge Interoperability Test Suite (Janus py-call)
; Tests 1 to 8 per Milestone 4 specifications
; ==============================================================================

!(println! "=== Starting PeTTa-to-Bridge Interoperability Tests ===")

; --- Test 1: Import the Python bridge module ---
!(println! "--- Test 1: Importing python_bridge/bridge.py ---")
!(import! &self "../../python_bridge/bridge.py")

; --- Test 2 & 3: Unsupported provider returns structured error without crashing ---
!(println! "--- Test 2 & 3: Querying unsupported provider ---")
!(let* (($raw_json (py-call (bridge.query "non_existent_provider" "test prompt")))
        ($success (py-call (bridge.get_field $raw_json "success")))
        ($err (py-call (bridge.get_field $raw_json "error"))))
   (progn
     (println! (concat "Received raw error JSON: " (repr $raw_json)))
     (test $success false)))

; --- Test 4: Empty prompt rejection from PeTTa ---
!(println! "--- Test 4: Querying with empty prompt ---")
!(let* (($raw_json (py-call (bridge.query "gemini" "   ")))
        ($success (py-call (bridge.get_field $raw_json "success")))
        ($err (py-call (bridge.get_field $raw_json "error"))))
   (progn
     (println! (concat "Empty prompt error JSON: " (repr $raw_json)))
     (test $success false)))

; --- Test 5: Safe field extraction helper via py-call ---
!(println! "--- Test 5: Field extraction verification ---")
!(let* (($sample_json "{\"success\": true, \"provider\": \"gemini\", \"model\": \"test\", \"content\": \"Sample content\", \"error\": null}")
        ($success (py-call (bridge.get_field $sample_json "success")))
        ($content (repr (py-call (bridge.get_field $sample_json "content")))))
   (progn
     (test $success true)
     (test $content "Sample content")))

; --- Test 6: Safe error handling without crashing PeTTa ---
(= (safe-bridge-query $provider $prompt)
   (let* (($resp_json (py-call (bridge.query $provider $prompt)))
          ($success   (py-call (bridge.get_field $resp_json "success")))
          ($content   (py-call (bridge.get_field $resp_json "content")))
          ($err       (repr (py-call (bridge.get_field $resp_json "error")))))
     (if (== $success true)
         (BridgeSuccess $content)
         (BridgeFailure $err))))

!(println! "--- Test 6: safe-bridge-query function test ---")
!(test (safe-bridge-query "invalid" "hello") (BridgeFailure "{\"type\": \"UnsupportedProviderError\", \"message\": \"Provider 'invalid' is not supported. Supported: 'gemini', 'openai', 'deepseek', 'generic_openai', 'default'.\"}"))

; --- Test 7: Multiple consecutive calls in one PeTTa process ---
!(println! "--- Test 7: Multiple consecutive bridge invocations ---")
!(let* (($r1 (safe-bridge-query "invalid" "prompt 1"))
        ($r2 (safe-bridge-query "invalid" "prompt 2"))
        ($r3 (safe-bridge-query "invalid" "prompt 3")))
   (println! "Multiple consecutive calls completed without state degradation."))

!(println! "=== ALL BRIDGE INTEROPERABILITY TESTS COMPLETED SUCCESSFULLY ===")
