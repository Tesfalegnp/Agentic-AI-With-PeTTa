;; =============================================================================
;; STAGE C - MILESTONE 9: Agent Controller and Terminal Interface
;; Module: agent/controller.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "loop.metta")
!(import! &self "memory_core.metta")
!(import! &self "adaptation_persistence.metta")

;; Check if input is a session termination keyword
(= (is-exit-command $cmd)
   (if (or (== $cmd "exit") (or (== $cmd "quit") (== $cmd "bye")))
       true
       false))

;; Dispatch and format agent response
(= (handle-user-query $query)
   (let $res (run-cognitive-cycle "default" $query 25)
     (case $res
       (((AgentResult answer $ans)
         (println! (string_concat "\nAgent: " $ans)))

        ((AgentResult ask_user $q)
         (println! (string_concat "\nAgent: " $q)))

        ((AgentResult finish $s)
         (println! (string_concat "\nAgent (Finished): " $s)))

        ((AgentResult error $err)
         (println! (string_concat "\nAgent (Error): " $err)))

        ((AgentResult unsupported $kind $reason)
         (println! (string_concat "\nAgent: " $reason)))

        ((AgentResult max_iterations_exceeded $m)
         (println! (string_concat "\nAgent: " $m)))

        ($_
         (println! "\nAgent: Unable to process request."))))))

;; Main interactive conversational loop
(= (agent-chat-loop)
   (progn
     (print! "\nYou: ")
     (let $query (readln!)
       (if (is-exit-command $query)
           (progn
             (memory-shutdown)
             (adaptation-save-to-disk)
             (println! "\nAgent: Goodbye! (Memory & Adaptations persisted safely)"))
           (progn
             (handle-user-query $query)
             (agent-chat-loop))))))

;; Agent Lifecycle Initializer
(= (run-agent)
   (progn
     (println! "=================================================")
     (println! "          PeTTa Agentic AI Framework             ")
     (println! "=================================================")
     (println! "Status: Full Agent Subsystems Active (Milestone 12)")
     (println! "Capabilities: Tools, Skills, Persistent Memory, Goal-Driven Planning, Adaptive Learning")
     (println! "Supported Actions: answer, ask_user, finish, error, use_tool, use_skill, remember, recall")
     (println! "Type 'exit', 'quit', or 'bye' to terminate session.\n")
     (memory-init)
     (adaptation-load-from-disk)
     (agent-chat-loop)))
