;; =============================================================================
;; STAGE C - MILESTONE 8: Skill Execution History
;; Module: agent/skill_history.metta
;; =============================================================================

;; Dedicated AtomSpace for Skill Execution History
!(bind! &skill_history (new-space))

;; Add a skill execution record
;; (history-record-skill-call $skill $args $status $result $steps_count)
(= (history-record-skill-call $skill $args $status $result $steps_count)
   (let* (($existing (collapse (match &skill_history (SkillExecutionRecord $s $sk $a $st $r $c) $s)))
          ($seq (+ (length $existing) 1)))
     (progn
       (add-atom &skill_history (SkillExecutionRecord $seq $skill $args $status $result $steps_count))
       (HistoryRecorded $seq $skill))))

;; Retrieve all skill execution records
(= (skill-history-list)
   (collapse (match &skill_history (SkillExecutionRecord $s $skill $args $status $result $steps_count)
               (SkillHistoryEntry $s $skill $status $result $steps_count))))

;; Retrieve execution records for a specific skill
(= (skill-history-get-by-skill $target_skill)
   (collapse (match &skill_history (SkillExecutionRecord $s $target_skill $args $status $result $steps_count)
               (SkillHistoryEntry $s $target_skill $status $result $steps_count))))

;; Clear skill history
(= (skill-history-clear)
   (let $records (collapse (match &skill_history $x (remove-atom &skill_history $x)))
     "Skill history cleared."))
