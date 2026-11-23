;; =============================================================================
;; STAGE C - MILESTONE 8: Central Skill Registry
;; Module: agent/skill_registry.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function atomic_list_concat)
!(import_prolog_function string_concat)

;; Dedicated AtomSpace for Skill Registry
!(bind! &skill_registry (new-space))

;; Metadata schema:
;; (SkillDefinition $name $description $args_schema $workflow_steps $returns $enabled)

(= (register-skill $name $description $args_schema $workflow_steps $returns $enabled)
   (let $existing (collapse (match &skill_registry (SkillDefinition $name $d $a $s $r $e) $name))
     (if (== $existing ())
         (progn
           (add-atom &skill_registry (SkillDefinition $name $description $args_schema $workflow_steps $returns $enabled))
           (RegistrationSuccess $name))
         (RegistrationDuplicate $name))))

(= (is-skill-registered $name)
   (let $entries (collapse (match &skill_registry (SkillDefinition $name $d $a $s $r $e) $name))
     (if (== $entries ())
         false
         true)))

(= (is-skill-enabled $name)
   (let $enabled_states (collapse (match &skill_registry (SkillDefinition $name $d $a $s $r true) $name))
     (if (== $enabled_states ())
         false
         true)))

(= (enable-skill $name)
   (let $found (collapse (match &skill_registry (SkillDefinition $name $d $a $s $r $e)
                           (progn
                             (remove-atom &skill_registry (SkillDefinition $name $d $a $s $r $e))
                             (add-atom &skill_registry (SkillDefinition $name $d $a $s $r true)))))
     (if (== $found ())
         (Error unknown_skill $name)
         (SkillEnabled $name))))

(= (disable-skill $name)
   (let $found (collapse (match &skill_registry (SkillDefinition $name $d $a $s $r $e)
                           (progn
                             (remove-atom &skill_registry (SkillDefinition $name $d $a $s $r $e))
                             (add-atom &skill_registry (SkillDefinition $name $d $a $s $r false)))))
     (if (== $found ())
         (Error unknown_skill $name)
         (SkillDisabled $name))))

(= (get-skill-definition $name)
   (let $def (collapse (match &skill_registry (SkillDefinition $name $d $a $s $r $e)
                         (SkillDefinition $name $d $a $s $r $e)))
     (case $def
       ((($entry) $entry)
        ($_ (Error unknown_skill $name))))))

(= (list-registered-skills)
   (collapse (match &skill_registry (SkillDefinition $name $d $a $s $r $e) $name)))

(= (list-enabled-skills)
   (collapse (match &skill_registry (SkillDefinition $name $d $a $s $r true) $name)))

;; Format all enabled skills dynamically for inclusion in system prompt
(= (format-skills-for-prompt)
   (let $entries (collapse (match &skill_registry (SkillDefinition $name $desc $args $steps $returns true)
                             (string_concat "- " (string_concat (repr $name)
                               (string_concat ": " (string_concat $desc
                                 (string_concat " Usage: (action use_skill "
                                   (string_concat (repr $name) (string_concat " " (string_concat (repr $args) ")"))))))))))
     (if (== $entries ())
         "No skills currently available."
         (atomic_list_concat $entries "\n"))))

;; Initialize and register the 3 built-in skills
(= (init-builtin-skills)
   (progn
     (register-skill math_skill
                    "Evaluates a multi-step mathematical calculation workflow using the calculator tool."
                    ((expression string required "Mathematical expression string, e.g. '125 * 8'"))
                    ((step 1 (tool_step s1 calculator ($expr)))
                     (step 2 (transform_step s2 format_result (ref s1))))
                    number
                    true)
     (register-skill text_process_skill
                    "Performs a multi-step text analysis workflow combining word counting and structural metrics."
                    ((text string required "Input text string to analyze"))
                    ((step 1 (tool_step s1 word_counter ($text)))
                     (step 2 (tool_step s2 text_analyzer ($text)))
                     (step 3 (combine_step s3 combine_text_metrics ((ref s1) (ref s2)))))
                    (TextMetrics words chars lines sentences)
                    true)
     (register-skill research_skill
                    "Prepares and structures a topic for text-based analysis and baseline metrics without live web browsing."
                    ((topic string required "Topic or content string to investigate"))
                    ((step 1 (tool_step s1 datetime ()))
                     (step 2 (tool_step s2 text_analyzer ($topic)))
                     (step 3 (combine_step s3 format_research_summary ((ref s1) (ref s2) $topic))))
                    (ResearchReport topic timestamp metrics)
                    true)
     (SkillsInitialized 3)))

;; Auto-initialize standard skill registry
!(init-builtin-skills)
