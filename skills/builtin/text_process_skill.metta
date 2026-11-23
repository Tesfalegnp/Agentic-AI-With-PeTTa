;; =============================================================================
;; STAGE C - MILESTONE 8: Built-in Skill - Text Process Skill
;; Module: skills/builtin/text_process_skill.metta
;; =============================================================================

!(import! &self "../../agent/tool_dispatcher.metta")
!(import! &self "../../agent/skill_result.metta")
!(import! &self "../../agent/skill_context.metta")

;; Step 2 & 3: Run text_analyzer and combine metrics
(= (run-text-process-step2 $wc $text)
   (let $res2 (dispatch-tool text_analyzer ($text))
     (case $res2
       (((ToolResult success text_analyzer $analysis)
         (progn
           (context-store s2 $analysis)
           (let $combined (TextMetrics $wc $analysis)
             (progn
               (context-store s3 $combined)
               (make-skill-success text_process_skill $combined)))))
        ((ToolResult failure text_analyzer $err2)
         (make-skill-failure text_process_skill $err2))
        ($_ (make-skill-failure text_process_skill "Malformed text_analyzer result."))))))

;; Executes multi-step text process workflow:
;; Step 1: Run word_counter tool
;; Step 2: Run text_analyzer tool
;; Step 3: Combine metrics into structured result
(= (run-text-process-skill $args)
   (case $args
     ((($text)
       (progn
         (context-init)
         (let $res1 (dispatch-tool word_counter ($text))
           (case $res1
             (((ToolResult success word_counter $wc)
               (progn
                 (context-store s1 $wc)
                 (run-text-process-step2 $wc $text)))
              ((ToolResult failure word_counter $err1)
               (make-skill-failure text_process_skill $err1))
              ($_ (make-skill-failure text_process_skill "Malformed word_counter result.")))))))
      ($_ (make-skill-failure text_process_skill "Invalid argument count for text_process_skill.")))))
