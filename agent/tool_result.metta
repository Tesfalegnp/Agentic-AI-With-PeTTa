;; =============================================================================
;; STAGE C - MILESTONE 7: Standardized Tool Results
;; Module: agent/tool_result.metta
;; =============================================================================

;; Result constructors
;; (ToolResult success $tool_name $value)
;; (ToolResult failure $tool_name $error_message)

(= (make-tool-success $tool $val)
   (ToolResult success $tool $val))

(= (make-tool-failure $tool $err)
   (ToolResult failure $tool $err))

(= (is-tool-success (ToolResult success $t $v)) true)
(= (is-tool-success (ToolResult failure $t $e)) false)

(= (get-tool-result-value (ToolResult success $t $v)) $v)
(= (get-tool-result-value (ToolResult failure $t $e)) "")

(= (get-tool-result-error (ToolResult success $t $v)) "")
(= (get-tool-result-error (ToolResult failure $t $e)) $e)

;; Format tool result for insertion into LLM prompt / observation
(= (format-tool-observation $result)
   (case $result
     (((ToolResult success $tool $val)
       (string_concat "[Observation from " (string_concat (repr $tool) (string_concat "]: " (repr $val)))))
      ((ToolResult failure $tool $err)
       (string_concat "[Observation from " (string_concat (repr $tool) (string_concat " ERROR]: " (repr $err)))))
      ($_ "[Observation]: Unknown tool result format."))))
