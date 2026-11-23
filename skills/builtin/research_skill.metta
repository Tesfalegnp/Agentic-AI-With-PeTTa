;; =============================================================================
;; STAGE C - MILESTONE 8: Built-in Skill - Research Skill
;; Module: skills/builtin/research_skill.metta
;; =============================================================================

!(import! &self "../../agent/tool_dispatcher.metta")
!(import! &self "../../agent/skill_result.metta")
!(import! &self "../../agent/skill_context.metta")

;; Step 2 & 3: Run text_analyzer and format research report
(= (run-research-step2 $dt $topic)
   (let $res2 (dispatch-tool text_analyzer ($topic))
     (case $res2
       (((ToolResult success text_analyzer $analysis)
         (progn
           (context-store s2 $analysis)
           (let $report (ResearchReport $topic $dt $analysis "Structured research baseline prepared. Note: Live web browsing is not yet supported.")
             (progn
               (context-store s3 $report)
               (make-skill-success research_skill $report)))))
        ((ToolResult failure text_analyzer $err2)
         (make-skill-failure research_skill $err2))
        ($_ (make-skill-failure research_skill "Malformed text_analyzer result."))))))

;; Executes structured research preparation workflow:
;; Step 1: Run datetime tool to timestamp research
;; Step 2: Run text_analyzer tool on topic
;; Step 3: Combine into structured report (explicitly noting no live browsing)
(= (run-research-skill $args)
   (case $args
     ((($topic)
       (progn
         (context-init)
         (let $res1 (dispatch-tool datetime ())
           (case $res1
             (((ToolResult success datetime $dt)
               (progn
                 (context-store s1 $dt)
                 (run-research-step2 $dt $topic)))
              ((ToolResult failure datetime $err1)
               (make-skill-failure research_skill $err1))
              ($_ (make-skill-failure research_skill "Malformed datetime result.")))))))
      ($_ (make-skill-failure research_skill "Invalid argument count for research_skill.")))))
