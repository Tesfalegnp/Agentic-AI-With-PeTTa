;; =============================================================================
;; STAGE C - MILESTONE 7: Tool Execution History
;; Module: agent/tool_history.metta
;; =============================================================================

;; Dedicated AtomSpace for Tool Execution History
!(bind! &tool_history (new-space))

;; Add a tool execution record
;; (history-record $seq $tool $args $status $result)
(= (history-record-tool-call $tool $args $status $result)
   (let* (($existing (collapse (match &tool_history (ToolExecutionRecord $s $t $a $st $r) $s)))
          ($seq (+ (length $existing) 1)))
     (progn
       (add-atom &tool_history (ToolExecutionRecord $seq $tool $args $status $result))
       (HistoryRecorded $seq $tool))))

;; Retrieve all tool execution records
(= (history-list-recent)
   (collapse (match &tool_history (ToolExecutionRecord $s $tool $args $status $result)
               (HistoryEntry $s $tool $status $result))))

;; Retrieve execution records for a specific tool
(= (history-get-by-tool $target_tool)
   (collapse (match &tool_history (ToolExecutionRecord $s $target_tool $args $status $result)
               (HistoryEntry $s $target_tool $status $result))))

;; Clear tool history
(= (history-clear)
   (let $records (collapse (match &tool_history $x (remove-atom &tool_history $x)))
     "Tool history cleared."))
