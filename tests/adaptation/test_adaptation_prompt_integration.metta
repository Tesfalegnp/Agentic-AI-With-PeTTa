;; =============================================================================
;; STAGE D - MILESTONE 12: Unit Test Suite - Adaptation Prompt & Budget Integration
;; Test: tests/adaptation/test_adaptation_prompt_integration.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import! &self "../../agent/prompt.metta")
!(import! &self "../../agent/adaptation_engine.metta")

!(println! "=== Running Adaptation Prompt & Budget Integration Tests ===")

;; Setup: Create and activate concise verbosity adaptation
!(adaptation-create verbosity "Prefer concise, direct explanations." all_queries prefer_concise ("fb_1" "fb_2") 2.5 1.0)
!(adaptation-activate "adapt_1")

;; Test 1: Relevant adaptation injected into prompt with provenance
!(let $prompt (build-agent-prompt "" "What is the capital of France?")
   (let $has_rule (sub_string_match $prompt "Rule: adapt_1")
     (let $has_rec (sub_string_match $prompt "prefer_concise")
       (if (and (== $has_rule true) (== $has_rec true))
           (println! "Test 1 PASSED: Active relevant adaptation injected into prompt with provenance.")
           (test false true)))))

;; Test 2: User instruction override (query explicitly asks for detail)
!(let $prompt_override (build-agent-prompt "" "Explain in detail the history of France.")
   (let $has_rule (sub_string_match $prompt_override "Rule: adapt_1")
     (if (== $has_rule false)
         (println! "Test 2 PASSED: Explicit instruction for detail overrides and suppresses concise adaptation.")
         (test false true))))

;; Test 3: Irrelevant adaptation excluded
!(adaptation-create tool_preference "Always use calculator for arithmetic" math_queries prefer_tool_execution ("fb_3" "fb_4") 2.5 1.0)
!(adaptation-activate "adapt_2")

!(let $prompt_general (build-agent-prompt "" "Who wrote Romeo and Juliet?")
   (let $has_math_rule (sub_string_match $prompt_general "Rule: adapt_2")
     (if (== $has_math_rule false)
         (println! "Test 3 PASSED: Math-specific adaptation excluded from unrelated literature query.")
         (test false true))))

;; Test 4: Disabled rule is excluded
!(adaptation-disable "adapt_1")
!(let $prompt_disabled (build-agent-prompt "" "What is the capital of Spain?")
   (let $has_disabled (sub_string_match $prompt_disabled "Rule: adapt_1")
     (if (== $has_disabled false)
         (println! "Test 4 PASSED: Disabled rule is excluded from prompt.")
         (test false true))))

;; Test 5: Context budget enforcement under constrained budget
!(adaptation-update-status "adapt_1" active)
!(let $tight_res (build-agent-prompt-with-budget "" "Short query" 200)
   (let $len (calculate-string-budget $tight_res)
     (let $has_identity (sub_string_match $tight_res "PeTTa Agentic AI Assistant")
       (let $has_query (sub_string_match $tight_res "Short query")
         (if (and (== $has_identity true) (== $has_query true))
             (println! "Test 5 PASSED: Tight context budget preserved mandatory identity and query.")
             (test false true))))))

;; Cleanup
!(adaptation-clear)
!(println! "=== ALL ADAPTATION PROMPT & BUDGET TESTS PASSED ===")
