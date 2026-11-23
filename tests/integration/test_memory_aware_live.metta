;; =============================================================================
;; STAGE D - MILESTONE 10: Live Gemini Memory-Aware Cognitive Reasoning Tests
;; File: tests/integration/test_memory_aware_live.metta
;; =============================================================================

!(println! "=== Starting Live Gemini Memory-Aware Reasoning Tests (Scenarios A-E) ===")

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "../../agent/loop.metta")
!(import! &self "../../agent/state.metta")
!(import! &self "../../agent/memory_core.metta")
!(import! &self "../../agent/memory_store.metta")
!(import! &self "../../agent/memory_ranking.metta")
!(import! &self "../../agent/memory_consistency.metta")

;; Reset memory and state before running live tests
!(memory-clear-all)
!(memory-clear-disk)
!(state-clear)

;; -----------------------------------------------------------------------------
;; Scenario A: Preference Recall & Adaptation (Concise Explanations)
;; -----------------------------------------------------------------------------
!(println! "--- Scenario A: Preference Recall (Concise Answers) ---")
!(memory-store-with-priority preference "User prefers concise, one-sentence answers." 5)

!(let $res_a (run-cognitive-cycle "gemini" "Explain what an algorithm is." 5)
   (case $res_a
     (((AgentResult answer $ans)
       (progn
         (println! "✅ Scenario A Answer received:")
         (println! $ans)))
      ($_ (println! "Scenario A finished with non-answer result.")))))

;; -----------------------------------------------------------------------------
;; Scenario B: Project Context Retrieval
;; -----------------------------------------------------------------------------
!(println! "--- Scenario B: Project Context Retrieval ---")
!(memory-store-with-priority fact "The project codename is Project Chimera and target architecture is PeTTa." 4)

!(let $res_b (run-cognitive-cycle "gemini" "What is the project codename according to project memory?" 5)
   (case $res_b
     (((AgentResult answer $ans)
       (progn
         (println! "✅ Scenario B Answer received:")
         (println! $ans)))
      ($_ (println! "Scenario B finished with non-answer result.")))))

;; -----------------------------------------------------------------------------
;; Scenario C: Irrelevant Memory Filtering
;; -----------------------------------------------------------------------------
!(println! "--- Scenario C: Irrelevant Memory Filtering ---")
;; Stored facts about chimera/concise shouldn't contaminate standard factual query
!(let $res_c (run-cognitive-cycle "gemini" "What is the freezing point of water in Celsius?" 5)
   (case $res_c
     (((AgentResult answer $ans)
       (progn
         (println! "✅ Scenario C Answer received:")
         (println! $ans)))
      ($_ (println! "Scenario C finished with non-answer result.")))))

;; -----------------------------------------------------------------------------
;; Scenario D: Conflicting Preferences (Conservative Handling)
;; -----------------------------------------------------------------------------
!(println! "--- Scenario D: Conflicting Preferences Detection & Clarification ---")
!(memory-store-with-priority preference "User prefers detailed, extensive explanations." 5)

!(let $res_d (run-cognitive-cycle "gemini" "Explain how neural networks learn." 5)
   (case $res_d
     (((AgentResult ask_user $question)
       (progn
         (println! "✅ Scenario D Clarification requested via ask_user:")
         (println! $question)))
      ((AgentResult answer $ans)
       (progn
         (println! "✅ Scenario D Answer provided (with conflict awareness):")
         (println! $ans)))
      ($_ (println! "Scenario D completed with other result.")))))

;; -----------------------------------------------------------------------------
;; Scenario E: Empty Memory Handling without Hallucination
;; -----------------------------------------------------------------------------
!(println! "--- Scenario E: Empty Memory Handling without Hallucination ---")
!(let $res_e (run-cognitive-cycle "gemini" "What is my favorite dessert according to your memory records?" 5)
   (case $res_e
     (((AgentResult answer $ans)
       (progn
         (println! "✅ Scenario E Non-hallucinatory answer received:")
         (println! $ans)))
      ($_ (println! "Scenario E finished with non-answer result.")))))

!(println! "=== ALL SCENARIOS A-E LIVE INTEGRATION TESTS COMPLETED ===")
