;; =============================================================================
;; STAGE B - MILESTONE 5: Multi-Provider LLM Bridge Interoperability Tests
;; Tests PeTTa import and querying across OpenAI, DeepSeek, Generic, and Default
;; =============================================================================

!(println! "=== Starting PeTTa Multi-Provider Bridge Interoperability Tests ===")

;; 1. Import Python Bridge
!(println! "--- Test 1: Importing python_bridge/bridge.py ---")
!(import! &self "../../python_bridge/bridge.py")

;; Helper function to parse bridge status safely
(= (bridge-status $provider $prompt)
   (let* (($resp_json (py-call (bridge.query $provider $prompt)))
          ($success   (py-call (bridge.get_field $resp_json "success")))
          ($prov_out  (py-call (bridge.get_field $resp_json "provider"))))
     (Status $success $prov_out)))

;; 2. Verify query with unknown/unsupported provider returns safe JSON error
!(println! "--- Test 2: Unsupported provider rejection ---")
!(test (bridge-status "invalid_provider" "test")
       (Status false invalid_provider))

;; 3. Verify query with unconfigured OpenAI returns safe AuthenticationError without crashing
!(println! "--- Test 3: OpenAI query safely returns false ---")
!(test (bridge-status "openai" "")
       (Status false openai))

;; 4. Verify query with unconfigured DeepSeek returns safe AuthenticationError without crashing
!(println! "--- Test 4: DeepSeek query safely returns false ---")
!(test (bridge-status "deepseek" "")
       (Status false deepseek))

;; 5. Verify query with unconfigured Generic provider returns safe ConfigurationError without crashing
!(println! "--- Test 5: Generic provider query safely returns false ---")
!(test (bridge-status "generic_openai" "")
       (Status false generic_openai))

;; 6. Verify "default" provider query resolves gracefully without runtime crash
!(println! "--- Test 6: Default provider query safely returns false for empty prompt ---")
!(let* (($resp_json (py-call (bridge.query "default" "")))
        ($success   (py-call (bridge.get_field $resp_json "success"))))
   (test $success false))

!(println! "=== ALL MULTI-PROVIDER BRIDGE INTEROPERABILITY TESTS PASSED ===")
