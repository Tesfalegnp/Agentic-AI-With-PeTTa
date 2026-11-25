;; =============================================================================
;; STAGE D - MILESTONE 13: UI Telemetry & Safe Gateway Interface
;; Module: agent/telemetry.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function consult)

;; Import Prolog telemetry and gateway primitives
!(import_prolog_functions_from_file "agent/telemetry_io.pl" (
    emit_telemetry_event
    clear_telemetry_events
    read_session_query
    write_session_result
    save_session_conversation
    load_session_conversation
    clear_session_conversation
    read_session_feedback
))

!(import! &self "state.metta")

;; Emit telemetry event to memory/session_events.jsonl
(= (emit-telemetry $event_type $stage $message $details)
   (let $res (emit_telemetry_event $event_type $stage $message $details)
     $res))

;; Clear telemetry events
(= (clear-telemetry)
   (let $res (clear_telemetry_events)
     $res))

;; Safe read user query from session file
(= (read-gateway-query)
   (let $q (read_session_query)
     $q))

;; Safe write final result to JSON
(= (write-gateway-result $status $action $content)
   (let $res (write_session_result $status $action $content)
     $res))

;; Save current &conversation state to session file
(= (state-save-session)
   (let $records (collapse (match &conversation $atom $atom))
     (save_session_conversation $records)))

;; Helper to restore conversation atoms into &conversation
(= (restore-conversation-records ()) true)
(= (restore-conversation-records $records)
   (let ($rec $rest) (decons-atom $records)
     (case $rec
       (((UserMessage $u)
         (progn
           (add-atom &conversation (UserMessage $u))
           (restore-conversation-records $rest)))
        ((AssistantMessage $a)
         (progn
           (add-atom &conversation (AssistantMessage $a))
           (restore-conversation-records $rest)))
        ((ClarificationState awaiting $q)
         (progn
           (add-atom &conversation (ClarificationState awaiting $q))
           (restore-conversation-records $rest)))
        ((PendingGoal $g)
         (progn
           (add-atom &conversation (PendingGoal $g))
           (restore-conversation-records $rest)))
        ((PendingPlan $p)
         (progn
           (add-atom &conversation (PendingPlan $p))
           (restore-conversation-records $rest)))
        ($_ (restore-conversation-records $rest))))))

;; Load conversation state from session file into &conversation
(= (state-load-session)
   (let $records (load_session_conversation)
     (restore-conversation-records $records)))

;; Clear session conversation state file
(= (state-clear-session)
   (progn
     (state-clear)
     (clear_session_conversation)))
