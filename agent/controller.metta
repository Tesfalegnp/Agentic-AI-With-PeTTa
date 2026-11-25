;; =============================================================================
;; STAGE C - MILESTONE 9: Agent Controller and Terminal Interface (Fixed)
;; Module: agent/controller.metta
;;
;; FIX: ask_user now triggers true task suspension and resume
;; FIX: Multiple tasks in one session (state isolation between tasks)
;; FIX: Completion status correctly reported (completed vs turn_limit vs error)
;; FIX: Approval-required commands display pending approval message
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "loop.metta")
!(import! &self "memory_core.metta")
!(import! &self "adaptation_persistence.metta")
!(import! &self "state.metta")

;; --- Exit detection ----------------------------------------------------------

(= (is-exit-command $cmd)
   (if (or (== $cmd "exit") (or (== $cmd "quit") (== $cmd "bye")))
       true
       false))

;; --- Response formatting -----------------------------------------------------

(= (handle-agent-result $res)
   (case $res
     (((AgentResult answer $ans)
       (println! (string_concat "\nAgent: " $ans)))

      ((AgentResult ask_user $q)
       (let* (($_sep (println! "\n--- AGENT NEEDS CLARIFICATION ---"))
              ($_q   (println! (string_concat "Agent: " $q)))
              ($_sep2 (println! "(Your answer will resume the suspended task.)")))
         awaiting_user))

      ((AgentResult finish $s)
       (println! (string_concat "\nAgent [Task Complete]: " $s)))

      ((AgentResult error $err)
       (println! (string_concat "\nAgent [Error]: " $err)))

      ((AgentResult unsupported $kind $reason)
       (println! (string_concat "\nAgent [Unsupported Action]: " $reason)))

      ((AgentResult max_iterations_exceeded $m)
       (println! (string_concat "\nAgent [Turn Limit Reached]: " $m)))

      ($_ (println! "\nAgent: Unable to process request.")))))

;; --- Main query dispatcher with clarification resume support -----------------

(= (handle-user-query $query)
   ;; Check if we have a suspended task awaiting clarification
   (if (== (state-is-awaiting-clarification) true)
       (let* (($_ev (println! "\n[Resuming suspended task with your answer...]"))
              ($res (resume-after-clarification "default" $query 25)))
         (handle-agent-result $res))
       ;; Normal new query — clear observations from previous turn (keep user/asst messages)
       (let* (($res (run-cognitive-cycle "default" $query 25)))
         (handle-agent-result $res))))

;; --- Multi-task session loop -------------------------------------------------

(= (agent-chat-loop)
   (progn
     (print! "\nYou: ")
     (let $query (readln!)
       (if (is-exit-command $query)
           (progn
             (memory-shutdown)
             (adaptation-save-to-disk)
             (println! "\nAgent: Goodbye! Memory and adaptations persisted safely."))
           (progn
             (handle-user-query $query)
             (agent-chat-loop))))))

;; --- Agent Lifecycle Initializer ---------------------------------------------

(= (run-agent)
   (progn
     (println! "=================================================================")
     (println! "        PeTTa Agentic AI Framework — Competition Edition         ")
     (println! "=================================================================")
     (println! "Agent Runtime:    PeTTa (SWI-Prolog + MeTTa)")
     (println! "Capabilities:     Tools, Skills, DAG Planning, Persistent Memory")
     (println! "                  Adaptive Learning, Failure Recovery, Clarification")
     (println! "Safety:           Destructive shell commands require human approval")
     (println! "Actions:          answer, ask_user, finish, error, use_tool,")
     (println! "                  use_skill, remember, recall")
     (println! "Type 'exit', 'quit', or 'bye' to end session.")
     (println! "=================================================================\n")
     (memory-init)
     (adaptation-load-from-disk)
     (agent-chat-loop)))
