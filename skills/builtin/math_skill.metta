;; =============================================================================
;; STAGE C - MILESTONE 8: Built-in Skill - Math Skill
;; Module: skills/builtin/math_skill.metta
;; =============================================================================

!(import! &self "../../agent/tool_dispatcher.metta")
!(import! &self "../../agent/skill_result.metta")
!(import! &self "../../agent/skill_context.metta")

;; Executes math calculation workflow:
;; Step 1: Run calculator tool
;; Step 2: Format and validate result
(= (run-math-skill $args)
   (case $args
     ((($expr)
       (progn
         (context-init)
         (let $tool_res (dispatch-tool calculator ($expr))
           (case $tool_res
             (((ToolResult success calculator $val)
               (progn
                 (context-store s1 $val)
                 (make-skill-success math_skill $val)))
              ((ToolResult failure calculator $err)
               (make-skill-failure math_skill $err))
              ($_ (make-skill-failure math_skill "Malformed tool result from calculator.")))))))
      ($_ (make-skill-failure math_skill "Invalid argument count for math_skill.")))))
