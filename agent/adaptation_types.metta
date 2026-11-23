;; =============================================================================
;; STAGE D - MILESTONE 12: Adaptive Learning & Feedback Subsystem Types
;; Module: agent/adaptation_types.metta
;; =============================================================================

;; Feedback Category Validation
(= (is-valid-feedback-category $cat)
   (case $cat
     ((answer_quality true)
      (verbosity true)
      (accuracy true)
      (tool_usage true)
      (skill_usage true)
      (planning_quality true)
      (task_completion true)
      (format_preference true)
      (clarification_quality true)
      (explanation_detail true)
      ($_ false))))

;; Feedback Polarity Validation
(= (is-valid-feedback-polarity $pol)
   (case $pol
     ((positive true)
      (negative true)
      (correction true)
      (neutral true)
      ($_ false))))

;; Feedback Target Type Validation
(= (is-valid-feedback-target-type $type)
   (case $type
     ((answer true)
      (tool true)
      (skill true)
      (plan true)
      (general true)
      ($_ false))))

;; Feedback Source Validation
(= (is-valid-feedback-source $src)
   (case $src
     ((explicit_user true)
      (inferred_signal true)
      ($_ false))))

;; Feedback Status Validation
(= (is-valid-feedback-status $status)
   (case $status
     ((active true)
      (superseded true)
      (archived true)
      ($_ false))))

;; Adaptation Category Validation
(= (is-valid-adaptation-category $cat)
   (case $cat
     ((verbosity true)
      (format_preference true)
      (explanation_detail true)
      (tool_preference true)
      (skill_preference true)
      (planning_preference true)
      (clarification_preference true)
      ($_ false))))

;; Bounded Behavioral Recommendation Validation
(= (is-valid-adaptation-recommendation $rec)
   (case $rec
     ((prefer_concise true)
      (prefer_detailed true)
      (include_calculations true)
      (omit_calculations true)
      (prefer_bullet_format true)
      (prefer_plain_text true)
      (prefer_json_format true)
      (avoid_markdown_table true)
      (prefer_tool_execution true)
      (prefer_skill_execution true)
      (ask_clarification_early true)
      ($_ false))))

;; Adaptation Status Validation
(= (is-valid-adaptation-status $status)
   (case $status
     ((candidate true)
      (active true)
      (suspended true)
      (disabled true)
      (superseded true)
      ($_ false))))

;; Adaptation Evaluation Status Validation
(= (is-valid-eval-status $status)
   (case $status
     ((insufficient_evidence true)
      (effective true)
      (neutral true)
      (review_needed true)
      (ineffective true)
      ($_ false))))
