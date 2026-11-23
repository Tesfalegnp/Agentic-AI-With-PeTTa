;; =============================================================================
;; STAGE C - MILESTONE 7: Conversation State and Context Management
;; Module: agent/state.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)

;; Bind a dedicated AtomSpace for conversational working memory
!(bind! &conversation (new-space))

;; Add a user message to &conversation
(= (state-add-user-message $msg)
   (add-atom &conversation (UserMessage $msg)))

;; Add an assistant response to &conversation
(= (state-add-assistant-message $msg)
   (add-atom &conversation (AssistantMessage $msg)))

;; Add a tool observation to &conversation
(= (state-add-observation $obs)
   (add-atom &conversation (Observation $obs)))

;; Retrieve all messages as formatted history
(= (state-get-context)
   (let $messages (collapse (match &conversation (UserMessage $u) (string_concat "User: " $u)))
     (if (== $messages ())
         "No prior conversation history."
         (repr $messages))))

;; Clear conversation state
(= (state-clear)
   (let $atoms (collapse (match &conversation $x (remove-atom &conversation $x)))
     "State cleared."))
