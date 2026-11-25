;; =============================================================================
;; STAGE C - MILESTONE 7: Conversation State and Context Management (Fixed)
;; Module: agent/state.metta
;;
;; FIX: state-get-context now returns ALL message types (user, assistant,
;; observation) in conversation order, not just user messages.
;; FIX: Added clarification state atoms for ask_user pause/resume.
;; FIX: Added task isolation atoms for multi-task sessions.
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)

;; Bind a dedicated AtomSpace for conversational working memory
!(bind! &conversation (new-space))

;; --- Message Tracking -------------------------------------------------------

;; Add a user message to &conversation
(= (state-add-user-message $msg)
   (add-atom &conversation (UserMessage $msg)))

;; Add an assistant response to &conversation
(= (state-add-assistant-message $msg)
   (add-atom &conversation (AssistantMessage $msg)))

;; Add a tool observation to &conversation
(= (state-add-observation $obs)
   (add-atom &conversation (Observation $obs)))

;; Add a failure/error record to &conversation
(= (state-add-failure $err)
   (add-atom &conversation (FailureRecord $err)))

;; Add a recovery attempt record
(= (state-add-recovery $attempt)
   (add-atom &conversation (RecoveryAttempt $attempt)))

;; --- Clarification State (ask_user Pause/Resume) ----------------------------

;; Record that the agent is awaiting clarification on a pending task
;; (state-mark-awaiting-clarification question pending-goal pending-plan)
(= (state-mark-awaiting-clarification $question $pending_goal $pending_plan)
   (let* (($_1 (add-atom &conversation (ClarificationState awaiting $question)))
          ($_2 (add-atom &conversation (PendingGoal $pending_goal)))
          ($_3 (add-atom &conversation (PendingPlan $pending_plan))))
     clarification_state_recorded))

;; Check if there is a pending clarification state
(= (state-is-awaiting-clarification)
   (let $matches (collapse (match &conversation (ClarificationState awaiting $q) $q))
     (if (== $matches ())
         false
         true)))

;; Get the pending clarification question
(= (state-get-clarification-question)
   (let $matches (collapse (match &conversation (ClarificationState awaiting $q) $q))
     (if (== $matches ())
         ""
         (car-atom $matches))))

;; Get the pending goal that was suspended for clarification
(= (state-get-pending-goal)
   (let $matches (collapse (match &conversation (PendingGoal $g) $g))
     (if (== $matches ())
         ""
         (car-atom $matches))))

;; Get the pending plan for the suspended task
(= (state-get-pending-plan)
   (let $matches (collapse (match &conversation (PendingPlan $p) $p))
     (if (== $matches ())
         ""
         (car-atom $matches))))

;; Clear clarification state after user answers
(= (state-clear-clarification)
   (let* (($_1 (collapse (match &conversation (ClarificationState awaiting $q)
                            (remove-atom &conversation (ClarificationState awaiting $q)))))
          ($_2 (collapse (match &conversation (PendingGoal $g)
                            (remove-atom &conversation (PendingGoal $g)))))
          ($_3 (collapse (match &conversation (PendingPlan $p)
                            (remove-atom &conversation (PendingPlan $p))))))
     clarification_state_cleared))

;; Add an approval request record
(= (state-add-approval-request $command $risk)
   (add-atom &conversation (ApprovalRequest $command $risk)))

;; --- Context Retrieval (Full: User + Assistant + Observations) ---------------

;; Retrieve all conversation messages in a structured text format
;; Includes user messages, assistant decisions, and tool observations.
;; This ensures the context window for the LLM is comprehensive.
(= (state-get-context)
   (let* (($user_msgs    (collapse (match &conversation (UserMessage $u) (string_concat "User: " $u))))
          ($asst_msgs    (collapse (match &conversation (AssistantMessage $a) (string_concat "Assistant: " $a))))
          ($observations (collapse (match &conversation (Observation $o) (string_concat "Observation: " $o))))
          ($failures     (collapse (match &conversation (FailureRecord $f) (string_concat "Error: " $f))))
          ($recoveries   (collapse (match &conversation (RecoveryAttempt $r) (string_concat "Recovery: " $r)))))
     (if (and (== $user_msgs ())
              (and (== $asst_msgs ())
                   (and (== $observations ())
                        (and (== $failures ()) (== $recoveries ())))))
         "No prior conversation history."
         (let* (($all_msgs (concatenate_conversations $user_msgs $asst_msgs $observations $failures $recoveries)))
           $all_msgs))))

;; Concatenate all conversation lists into a single formatted string
(= (concatenate_conversations $users $assts $obs $fails $recovs)
   (let* (($u_str (if (== $users ())   "" (string_concat "--- User Messages ---\n"       (repr $users))))
          ($a_str (if (== $assts ())   "" (string_concat "\n--- Assistant Actions ---\n"  (repr $assts))))
          ($o_str (if (== $obs ())     "" (string_concat "\n--- Tool Observations ---\n"  (repr $obs))))
          ($f_str (if (== $fails ())   "" (string_concat "\n--- Errors & Failures ---\n"  (repr $fails))))
          ($r_str (if (== $recovs ())  "" (string_concat "\n--- Recovery Attempts ---\n"  (repr $recovs)))))
     (string_concat $u_str (string_concat $a_str (string_concat $o_str (string_concat $f_str $r_str))))))

;; Get just user messages (for prompt construction)
(= (state-get-user-messages)
   (let $msgs (collapse (match &conversation (UserMessage $u) $u))
     (if (== $msgs ()) () $msgs)))

;; Get original task (first user message in session)
(= (state-get-original-task)
   (let $msgs (collapse (match &conversation (UserMessage $u) $u))
     (if (== $msgs ())
         ""
         (car-atom $msgs))))

;; Get latest user message
(= (state-get-latest-user-message)
   (let $msgs (collapse (match &conversation (UserMessage $u) $u))
     (if (== $msgs ())
         ""
         (let $reversed (reverse_list $msgs)
           (car-atom $reversed)))))

;; Reverse a list (helper for getting latest item)
(= (reverse_list ()) ())
(= (reverse_list $lst)
   (let* (($pair (decons-atom $lst))
          ($head (car-atom $pair))
          ($tail (car-atom (cdr-atom $pair)))
          ($rev_tail (reverse_list $tail)))
     (append_atom $rev_tail ($head))))

;; --- State Clearing ----------------------------------------------------------

;; Clear entire conversation state (task isolation)
(= (state-clear)
   (let $atoms (collapse (match &conversation $x (remove-atom &conversation $x)))
     "Conversation state cleared."))

;; Clear only observations (keep user/assistant context, discard old tool results)
(= (state-clear-observations)
   (let $atoms (collapse (match &conversation (Observation $o)
                            (remove-atom &conversation (Observation $o))))
     "Observations cleared."))

;; --- Task Completion Tracking -----------------------------------------------

;; Record task completion status
;; Status: completed | partial | blocked | failed | turn_limit
(= (state-record-completion-status $status $summary)
   (add-atom &conversation (TaskCompletion $status $summary)))

;; Get task completion status
(= (state-get-completion-status)
   (let $matches (collapse (match &conversation (TaskCompletion $s $sum) ($s $sum)))
     (if (== $matches ())
         (incomplete "No completion recorded yet.")
         (car-atom $matches))))
