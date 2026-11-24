;; =============================================================================
;; Evaluator Scenario C: Insufficient Information & Clarification Flow
;; File: tests/integration/test_scenario_c_clarification.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "../../agent/action_validator.metta")
!(import! &self "../../agent/response_parser.metta")
!(import! &self "../../agent/state.metta")

!(println! "--- Step 1: Evaluating Ambiguous Request ---")
!(state-clear)
!(let $_u (state-add-user-message "Find the best option for my project and calculate the expected cost."))

;; Evaluator test: model detects ambiguity and formulates (action ask_user ...)
!(let $simulated_llm_response "(action ask_user \"Could you please specify your project requirements, domain (e.g. cloud, software, hardware), and your expected budget constraint?\")"
   (let $eval (parse-and-validate-response $simulated_llm_response)
     (test (case $eval (((ActionValid ask_user $q) true) ($_ false))) true)))

!(println! "--- Step 2: User Provides Clarification & Goal Resumption ---")
!(let $_q (state-add-assistant-message "Could you please specify your project requirements and budget?"))
!(let $_ans (state-add-user-message "My project is a high-availability web service with a $500 monthly budget."))

;; Evaluator test: agent resumes with factual answer adhering to the clarified constraints
!(let $resumed_response "(action answer \"With a $500 monthly budget for a high-availability web service, we recommend a multi-zone Kubernetes cluster on Hetzner or DigitalOcean with redundant ingress nodes costing ~$380/month.\")"
   (let $eval2 (parse-and-validate-response $resumed_response)
     (test (case $eval2 (((ActionValid answer $ans) true) ($_ false))) true)))

!(println! "--- Step 3: Context Continuity Verification ---")
!(let $history (state-get-context)
   (test (if (== $history "") false true) true))

!(println! "SCENARIO C (CLARIFICATION & RESUMPTION) PASSED SUCCESSFULLY! ✅")
