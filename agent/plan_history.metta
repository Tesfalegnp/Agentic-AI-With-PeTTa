;; =============================================================================
;; STAGE D - MILESTONE 11: Plan Execution History & Audit Logger
;; Module: agent/plan_history.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import! &self "plan_state.metta")

!(bind! &plan_history (new-space))

;; Record an audit event in plan history
(= (plan-history-record $plan_id $task_id $event_type $details)
   (let $now (get_plan_timestamp)
     (progn
       (add-atom &plan_history (PlanHistoryEntry $now $plan_id $task_id $event_type $details))
       (PlanHistoryLogged $plan_id $task_id $event_type))))

;; Retrieve all plan history entries
(= (plan-history-list)
   (collapse (match &plan_history (PlanHistoryEntry $ts $pid $tid $event $det)
                    (PlanHistoryEntry $ts $pid $tid $event $det))))

;; Clear plan history (for tests and session reset)
(= (plan-history-clear)
   (progn
     (collapse (match &plan_history $x (remove-atom &plan_history $x)))
     "Plan history cleared."))
