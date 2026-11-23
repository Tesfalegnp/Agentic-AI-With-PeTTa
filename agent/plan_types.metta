;; =============================================================================
;; STAGE D - MILESTONE 11: Planning Subsystem Data Models & Types
;; Module: agent/plan_types.metta
;; =============================================================================

;; Status predicates for Goals
(= (is-valid-goal-status $status)
   (case $status
     ((active true)
      (completed true)
      (blocked true)
      (cancelled true)
      (failed true)
      ($_ false))))

;; Status predicates for Plans
(= (is-valid-plan-status $status)
   (case $status
     ((draft true)
      (validated true)
      (executing true)
      (completed true)
      (failed true)
      (blocked true)
      (cancelled true)
      ($_ false))))

;; Status predicates for Tasks
(= (is-valid-task-status $status)
   (case $status
     ((pending true)
      (ready true)
      (running true)
      (completed true)
      (failed true)
      (blocked true)
      (skipped true)
      (cancelled true)
      ($_ false))))

;; Executor types
(= (is-valid-executor-type $type)
   (case $type
     ((tool true)
      (skill true)
      ($_ false))))
