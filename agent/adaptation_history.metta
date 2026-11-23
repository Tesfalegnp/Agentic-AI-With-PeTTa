;; =============================================================================
;; STAGE D - MILESTONE 12: Learning & Adaptation History Audit Subsystem
;; Module: agent/adaptation_history.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "feedback_store.metta")

!(bind! &adaptation_history (new-space))

;; Initialize counter
!(add-atom &adaptation_history (AdaptationHistoryCounter 0))

;; Next Event ID generator
(= (adaptation-history-next-id)
   (let $c_atoms (collapse (match &adaptation_history (AdaptationHistoryCounter $c) $c))
     (let $current (if (== $c_atoms ()) 0 (car-atom $c_atoms))
       (let $next (+ $current 1)
         (progn
           (remove-atom &adaptation_history (AdaptationHistoryCounter $current))
           (add-atom &adaptation_history (AdaptationHistoryCounter $next))
           (string_concat "ev_" (repr $next)))))))

;; Record an audit event
(= (adaptation-history-record $event_type $target_id $details)
   (let* (($eid (adaptation-history-next-id))
          ($now (get_adaptation_timestamp))
          ($ev  (AdaptationHistoryEvent $eid $now $event_type $target_id $details)))
     (progn
       (add-atom &adaptation_history $ev)
       (AdaptationHistoryRecorded $eid $event_type))))

;; List all history events
(= (adaptation-history-list)
   (collapse (match &adaptation_history
                    (AdaptationHistoryEvent $eid $ts $ev_type $tid $details)
                    (AdaptationHistoryEvent $eid $ts $ev_type $tid $details))))

;; Clear history space
(= (adaptation-history-clear)
   (progn
     (collapse (match &adaptation_history $x (remove-atom &adaptation_history $x)))
     (add-atom &adaptation_history (AdaptationHistoryCounter 0))
     "Adaptation history space cleared."))
