;; =============================================================================
;; STAGE D - MILESTONE 11: Plan Proposal Parser & Plan Builder
;; Module: agent/plan_builder.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "plan_types.metta")
!(import! &self "plan_state.metta")
!(import! &self "response_parser.metta")

;; Normalize arguments (e.g. ((text "foo")) -> ("foo"), while keeping (ref t1))
(= (normalize-single-arg ($key $val))
   (if (== $key ref)
       ($key $val)
       $val))
(= (normalize-single-arg $arg) $arg)

(= (normalize-task-args ()) ())
(= (normalize-task-args $args)
   (let ($head $tail) (decons-atom $args)
     (cons-atom (normalize-single-arg $head) (normalize-task-args $tail))))

;; Add a list of task proposals into the plan state
(= (populate-plan-tasks $plan_id ()) (TasksPopulated $plan_id))
(= (populate-plan-tasks $plan_id $tasks)
   (let ($task $rest) (decons-atom $tasks)
     (case $task
       (((task $tid $type $name $args $deps)
         (let $norm_args (normalize-task-args $args)
           (progn
             (plan-add-task $plan_id $tid (string_concat "Execute " (repr $name)) $type $name $norm_args $deps)
             (populate-plan-tasks $plan_id $rest))))
        ($_ (PlanBuildError "Malformed task item in proposal."))))))

;; Parse raw proposal string
(= (parse-plan-proposal $raw_text)
   (if (== $raw_text "")
       (PlanProposalError "Empty plan proposal string.")
       (let* (($cleaned (clean_plan_string $raw_text))
              ($parsed  (safe-sread $cleaned)))
         (case $parsed
           (((ParseError $err) (PlanProposalError (string_concat "Syntax error parsing proposal: " (repr $err))))
            ((plan-proposal $desc $tasks) (PlanProposalParsed (plan-proposal $desc $tasks)))
            ($_ (PlanProposalError "Proposal must have format (plan-proposal \"description\" ((task ...) ...))")))))))

;; Build and store plan from a parsed plan-proposal structure
(= (build-plan-from-proposal $goal_id (plan-proposal $desc $tasks))
   (let $plan_res (plan-create $goal_id $desc)
     (case $plan_res
       (((PlanCreated $plan_id)
         (let $pop_res (populate-plan-tasks $plan_id $tasks)
           (case $pop_res
             (((TasksPopulated $pid) (PlanBuilt $plan_id))
              ((PlanBuildError $err) (PlanBuildFailed $err))))))
        ($_ (PlanBuildFailed "Unable to create plan in state."))))))
