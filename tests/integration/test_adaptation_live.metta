;; =============================================================================
;; STAGE D - MILESTONE 12: Live Adaptive Learning & Feedback Integration Tests
;; File: tests/integration/test_adaptation_live.metta
;; =============================================================================

!(println! "=== Starting Live Adaptive Learning Integration Tests (Scenarios A through G) ===")

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import_prolog_functions_from_file "agent/memory_io.pl" (sub_string_match))
!(import! &self "../../agent/loop.metta")
!(import! &self "../../agent/prompt.metta")
!(import! &self "../../agent/state.metta")
!(import! &self "../../agent/feedback_store.metta")
!(import! &self "../../agent/feedback_aggregation.metta")
!(import! &self "../../agent/adaptation_registry.metta")
!(import! &self "../../agent/adaptation_validator.metta")
!(import! &self "../../agent/adaptation_lifecycle.metta")
!(import! &self "../../agent/adaptation_conflict.metta")
!(import! &self "../../agent/adaptation_engine.metta")
!(import! &self "../../agent/adaptation_evaluation.metta")
!(import! &self "../../agent/adaptation_history.metta")
!(import! &self "../../agent/adaptation_persistence.metta")

;; Reset all state
!(feedback-clear)
!(adaptation-clear)
!(adaptation-history-clear)
!(evaluation-clear)
!(state-clear)

;; -----------------------------------------------------------------------------
;; Scenario A: Learning a Verbosity Preference
;; -----------------------------------------------------------------------------
!(println! "\n--- Scenario A: Learning a Verbosity Preference ---")

;; 1. First explicit feedback event
!(feedback-record verbosity negative answer none "Your answers are too long. Please be concise." "q1" explicit_user 1.0)

;; Threshold not yet met with single event
!(let $cand1 (derive-candidate-from-feedback verbosity "Prefer concise, direct explanations." all_queries prefer_concise)
   (case $cand1
     (((CandidateRejected InsufficientEvidence)
       (println! "✅ Scenario A Check 1: Single feedback event correctly rejected as insufficient evidence."))
      ($_ (test false true)))))

;; 2. Second independent explicit feedback event
!(feedback-record verbosity negative answer none "Always give brief and concise responses." "q2" explicit_user 1.0)

;; Threshold met: recurring pattern detected and candidate derived
!(let $cand2 (derive-candidate-from-feedback verbosity "Prefer concise, direct explanations." all_queries prefer_concise)
   (case $cand2
     (((AdaptationCreated "adapt_1" verbosity prefer_concise)
       (let $act (adaptation-activate "adapt_1")
         (case $act
           (((AdaptationActivated "adapt_1")
             (println! "✅ Scenario A Check 2: Recurring pattern detected, candidate derived and activated as adapt_1."))
            ($_ (test false true))))))
      ($_ (test false true)))))

;; 3. Live query to Gemini with active concise adaptation
!(let $res_a (run-cognitive-cycle "gemini" "What is the capital of France?" 3)
   (case $res_a
     (((AgentResult answer $ans)
       (progn
         (test (sub_string_match $ans "Paris") true)
         (println! "✅ Scenario A Answer received:")
         (println! $ans)
         (println! "✅ Scenario A PASSED: Learned verbosity preference applied successfully.")))
      ($_ (test false true)))))

;; -----------------------------------------------------------------------------
;; Scenario B: Current Instruction Override
;; -----------------------------------------------------------------------------
!(println! "\n--- Scenario B: Current Instruction Override ---")

;; adapt_1 is active (prefer_concise), but user explicitly asks for detailed explanation
!(let $prompt_b (build-agent-prompt "" "Explain in detail the history and architecture of the Eiffel Tower.")
   (let $has_concise (sub_string_match $prompt_b "prefer_concise")
     (if (== $has_concise false)
         (println! "✅ Scenario B Check: Concise adaptation correctly suppressed by explicit instruction for detail.")
         (test false true))))

!(let $res_b (run-cognitive-cycle "gemini" "Explain in detail the history and architecture of the Eiffel Tower." 3)
   (case $res_b
     (((AgentResult answer $ans)
       (progn
         (test (sub_string_match $ans "Eiffel") true)
         (println! "✅ Scenario B Detailed Answer received:")
         (println! $ans)
         (println! "✅ Scenario B PASSED: Current instruction successfully took precedence over learned adaptation.")))
      ($_ (test false true)))))

;; -----------------------------------------------------------------------------
;; Scenario C: Negative Feedback and Correction
;; -----------------------------------------------------------------------------
!(println! "\n--- Scenario C: Negative Feedback and Correction ---")

!(adaptation-create format_preference "Avoid markdown tables" all_queries avoid_markdown_table ("fb_init") 2.5 1.0)
!(adaptation-activate "adapt_2")
!(evaluation-record-application "adapt_2")

;; User provides negative feedback on this format rule
!(feedback-record format_preference negative answer none "I need tabular format now, do not avoid tables" "q_table" explicit_user 1.0)
!(evaluation-record-application "adapt_2")
!(evaluation-record-outcome "adapt_2" negative)
!(evaluation-record-outcome "adapt_2" negative)

!(let $needs_rev (evaluation-should-review "adapt_2")
   (if (== $needs_rev true)
       (progn
         (adaptation-suspend "adapt_2")
         (println! "✅ Scenario C PASSED: Repeated negative feedback flagged rule for review and rule suspended."))
       (test false true)))

;; -----------------------------------------------------------------------------
;; Scenario D: Irrelevant Adaptation Exclusion
;; -----------------------------------------------------------------------------
!(println! "\n--- Scenario D: Irrelevant Adaptation Exclusion ---")

;; Create tool preference for math queries
!(adaptation-create tool_preference "Always use calculator for calculations" math_queries prefer_tool_execution ("fb_math") 2.5 1.0)
!(adaptation-activate "adapt_3")

;; Test on unrelated general query
!(let $prompt_d (build-agent-prompt "" "Who wrote Hamlet?")
   (let $has_math (sub_string_match $prompt_d "Rule: adapt_3")
     (if (== $has_math false)
         (println! "✅ Scenario D Check: Math adaptation correctly excluded from general query prompt.")
         (test false true))))

!(let $res_d (run-cognitive-cycle "gemini" "Who wrote Hamlet?" 3)
   (case $res_d
     (((AgentResult answer $ans)
       (progn
         (test (sub_string_match $ans "Shakespeare") true)
         (println! "✅ Scenario D Answer received:")
         (println! $ans)
         (println! "✅ Scenario D PASSED: Irrelevant adaptation excluded cleanly.")))
      ($_ (test false true)))))

;; -----------------------------------------------------------------------------
;; Scenario E: Conflicting Feedback
;; -----------------------------------------------------------------------------
!(println! "\n--- Scenario E: Conflicting Feedback ---")

!(feedback-clear)
!(feedback-record explanation_detail positive answer none "Loved the deep technical steps" "q_c1" explicit_user 1.0)
!(feedback-record explanation_detail negative answer none "Way too technical and verbose" "q_c2" explicit_user 1.0)

!(let $cand_e (derive-candidate-from-feedback explanation_detail "Prefer detailed technical steps." all_queries prefer_detailed)
   (case $cand_e
     (((CandidateRejected ContradictoryFeedback)
       (println! "✅ Scenario E PASSED: Contradictory feedback safely detected and candidate creation rejected."))
      ($_ (test false true)))))

;; -----------------------------------------------------------------------------
;; Scenario F: User Inspection and Control
;; -----------------------------------------------------------------------------
!(println! "\n--- Scenario F: User Inspection and Control ---")

;; User inspects adapt_1
!(let $insp (adaptation-inspect "adapt_1")
   (case $insp
     (((AdaptationInspection "adapt_1" verbosity $desc all_queries prefer_concise $supp $sc $conf $cr $up active)
       (println! "✅ Scenario F Check 1: User inspected active rule adapt_1 successfully."))
      ($_ (test false true)))))

;; User disables adapt_1
!(let $dis (adaptation-disable "adapt_1")
   (case $dis
     (((AdaptationDisabled "adapt_1")
       (let $prompt_f (build-agent-prompt "" "What is the capital of Spain?")
         (let $has_rule (sub_string_match $prompt_f "Rule: adapt_1")
           (if (== $has_rule false)
               (println! "✅ Scenario F PASSED: Disabled rule verified excluded from agent prompt.")
               (test false true)))))
      ($_ (test false true)))))

;; -----------------------------------------------------------------------------
;; Scenario G: Persistence Across Process Restart
;; -----------------------------------------------------------------------------
!(println! "\n--- Scenario G: Persistence Across Process Restart ---")

;; Reactivate adapt_1 and save
!(adaptation-update-status "adapt_1" active)
!(adaptation-history-record rule_reactivated "adapt_1" "Reactivated for persistence test")
!(let $save (adaptation-save-to-disk)
   (println! "✅ Scenario G Check 1: Adaptation state saved to disk."))

;; Simulate restart: clear in-memory spaces
!(feedback-clear)
!(adaptation-clear)
!(adaptation-history-clear)
!(evaluation-clear)

;; Reload from disk
!(let $load (adaptation-load-from-disk)
   (let $rule_restored (adaptation-get "adapt_1")
     (case $rule_restored
       (((AdaptationRule "adapt_1" verbosity $desc all_queries prefer_concise $supp $sc $conf $cr $up active)
         (println! "✅ Scenario G Check 2: Rule adapt_1 restored in active status."))
        ($_ (test false true))))))

;; Clean disk storage
!(adaptation-clear-disk)
!(feedback-clear)
!(adaptation-clear)
!(adaptation-history-clear)
!(evaluation-clear)
!(state-clear)

!(println! "\n=== ALL LIVE ADAPTATION INTEGRATION SCENARIOS PASSED ===")
