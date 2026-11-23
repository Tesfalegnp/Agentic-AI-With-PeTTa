;; =============================================================================
;; STAGE C - MILESTONE 7: Central Tool Registry
;; Module: agent/tool_registry.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function atomic_list_concat)
!(import_prolog_function string_concat)

;; Dedicated AtomSpace for Tool Registry
!(bind! &tool_registry (new-space))

;; Metadata schema:
;; (ToolDefinition $name $description $args_schema $returns $enabled)

(= (register-tool $name $description $args_schema $returns $enabled)
   (let $existing (collapse (match &tool_registry (ToolDefinition $name $d $a $r $e) $name))
     (if (== $existing ())
         (progn
           (add-atom &tool_registry (ToolDefinition $name $description $args_schema $returns $enabled))
           (RegistrationSuccess $name))
         (RegistrationDuplicate $name))))

(= (is-tool-registered $name)
   (let $entries (collapse (match &tool_registry (ToolDefinition $name $d $a $r $e) $name))
     (if (== $entries ())
         false
         true)))

(= (is-tool-enabled $name)
   (let $enabled_states (collapse (match &tool_registry (ToolDefinition $name $d $a $r true) $name))
     (if (== $enabled_states ())
         false
         true)))

(= (enable-tool $name)
   (let $found (collapse (match &tool_registry (ToolDefinition $name $d $a $r $e)
                           (progn
                             (remove-atom &tool_registry (ToolDefinition $name $d $a $r $e))
                             (add-atom &tool_registry (ToolDefinition $name $d $a $r true)))))
     (if (== $found ())
         (Error unknown_tool $name)
         (ToolEnabled $name))))

(= (disable-tool $name)
   (let $found (collapse (match &tool_registry (ToolDefinition $name $d $a $r $e)
                           (progn
                             (remove-atom &tool_registry (ToolDefinition $name $d $a $r $e))
                             (add-atom &tool_registry (ToolDefinition $name $d $a $r false)))))
     (if (== $found ())
         (Error unknown_tool $name)
         (ToolDisabled $name))))

(= (list-registered-tools)
   (collapse (match &tool_registry (ToolDefinition $name $d $a $r $e) $name)))

(= (list-enabled-tools)
   (collapse (match &tool_registry (ToolDefinition $name $d $a $r true) $name)))

;; Format all enabled tools dynamically for inclusion in system prompt
(= (format-tools-for-prompt)
   (let $entries (collapse (match &tool_registry (ToolDefinition $name $desc $args $returns true)
                             (string_concat "- " (string_concat (repr $name)
                               (string_concat ": " (string_concat $desc
                                 (string_concat " Usage: (action use_tool "
                                   (string_concat (repr $name) (string_concat " " (string_concat (repr $args) ")"))))))))))
     (if (== $entries ())
         "No tools currently available."
         (atomic_list_concat $entries "\n"))))

;; Initialize and register the 5 built-in tools
(= (init-builtin-tools)
   (progn
     (register-tool calculator
                    "Evaluates a basic mathematical expression (+, -, *, /)."
                    ((expression string required "Mathematical expression string, e.g. '25 * 4'"))
                    number
                    true)
     (register-tool word_counter
                    "Counts the total words in a text string."
                    ((text string required "Input text string to count"))
                    number
                    true)
     (register-tool text_analyzer
                    "Computes character, word, line, and sentence counts."
                    ((text string required "Input text string to analyze"))
                    (TextAnalysis chars words lines sentences)
                    true)
     (register-tool string_reverser
                    "Reverses the characters of a text string."
                    ((text string required "Input text string to reverse"))
                    string
                    true)
     (register-tool datetime
                    "Returns the current system date and time in UTC."
                    ()
                    string
                    true)
     (RegistryInitialized 5)))

;; Auto-initialize standard registry
!(init-builtin-tools)
