;; =============================================================================
;; STAGE D - MILESTONE 12: Feedback Capture & Store Subsystem
;; Module: agent/feedback_store.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import_prolog_functions_from_file "agent/adaptation_io.pl" (save_feedback_records load_feedback_records save_adaptation_rules load_adaptation_rules save_adaptation_history load_adaptation_history save_adaptation_evals load_adaptation_evals clear_adaptation_file check_instruction_adaptation_conflict is_adaptation_relevant_to_query aggregate_feedback_in_space get_supporting_feedback_ids detect_adaptation_rule_conflicts_in_space get_adaptation_timestamp clean_feedback_text is_valid_confidence_val))
!(import! &self "adaptation_types.metta")

!(bind! &feedback_space (new-space))

;; Initialize counter
!(add-atom &feedback_space (FeedbackCounter 0))

;; Next Feedback ID generator
(= (feedback-next-id)
   (let $c_atoms (collapse (match &feedback_space (FeedbackCounter $c) $c))
     (let $current (if (== $c_atoms ()) 0 (car-atom $c_atoms))
       (let $next (+ $current 1)
         (progn
           (remove-atom &feedback_space (FeedbackCounter $current))
           (add-atom &feedback_space (FeedbackCounter $next))
           (string_concat "fb_" (repr $next)))))))

;; Validate feedback parameters
(= (validate-feedback-params $cat $pol $target_type $src $conf)
   (if (== (is-valid-feedback-category $cat) false)
       (FeedbackValidationError (string_concat "Invalid feedback category: " (repr $cat)))
       (if (== (is-valid-feedback-polarity $pol) false)
           (FeedbackValidationError (string_concat "Invalid feedback polarity: " (repr $pol)))
           (if (== (is-valid-feedback-target-type $target_type) false)
               (FeedbackValidationError (string_concat "Invalid feedback target type: " (repr $target_type)))
               (if (== (is-valid-feedback-source $src) false)
                   (FeedbackValidationError (string_concat "Invalid feedback source: " (repr $src)))
                   (if (== (is_valid_confidence_val $conf) false)
                       (FeedbackValidationError (string_concat "Invalid confidence value: " (repr $conf)))
                       FeedbackValidationSuccess))))))

;; Check for duplicate feedback: identical category, target_id, and cleaned text
(= (find-duplicate-feedback $cat $target_id $clean_txt)
   (let $found (collapse (match &feedback_space
                                (FeedbackRecord $id $cat $pol $tt $target_id $clean_txt $ctx $src $conf $ts active)
                                $id))
     (if (== $found ())
         no_duplicate
         (car-atom $found))))

(= (feedback-record-validated $category $polarity $target_type $target_id $clean_txt $context $source $confidence)
   (let $dup (find-duplicate-feedback $category $target_id $clean_txt)
     (if (== $dup no_duplicate)
         (let* (($fid (feedback-next-id))
                ($ts  (get_adaptation_timestamp))
                ($rec (FeedbackRecord $fid $category $polarity $target_type $target_id $clean_txt $context $source $confidence $ts active)))
           (progn
             (add-atom &feedback_space $rec)
             (FeedbackRecorded $fid $category $polarity $clean_txt)))
         (FeedbackDuplicate $dup))))

;; Capture and record feedback
(= (feedback-record $category $polarity $target_type $target_id $raw_text $context $source $confidence)
   (let $val (validate-feedback-params $category $polarity $target_type $source $confidence)
     (case $val
       (((FeedbackValidationError $err) (FeedbackValidationFailed $err))
        (FeedbackValidationSuccess
         (let $clean_txt (clean_feedback_text $raw_text)
           (feedback-record-validated $category $polarity $target_type $target_id $clean_txt $context $source $confidence)))))))

;; Retrieve feedback by ID
(= (feedback-get $id)
   (let $found (collapse (match &feedback_space
                                (FeedbackRecord $id $cat $pol $tt $tid $txt $ctx $src $conf $ts $st)
                                (FeedbackRecord $id $cat $pol $tt $tid $txt $ctx $src $conf $ts $st)))
     (if (== $found ())
         (FeedbackNotFound $id)
         (car-atom $found))))

;; List feedback records by category ('all' retrieves all active records)
(= (feedback-list $category)
   (if (== $category all)
       (collapse (match &feedback_space
                        (FeedbackRecord $id $cat $pol $tt $tid $txt $ctx $src $conf $ts active)
                        (FeedbackRecord $id $cat $pol $tt $tid $txt $ctx $src $conf $ts active)))
       (collapse (match &feedback_space
                        (FeedbackRecord $id $category $pol $tt $tid $txt $ctx $src $conf $ts active)
                        (FeedbackRecord $id $category $pol $tt $tid $txt $ctx $src $conf $ts active)))))

;; Update feedback status
(= (feedback-update-status $id $new_status)
   (if (== (is-valid-feedback-status $new_status) false)
       (FeedbackStatusUpdateFailed (string_concat "Invalid feedback status: " (repr $new_status)))
       (let $found (feedback-get $id)
         (case $found
           (((FeedbackRecord $id $cat $pol $tt $tid $txt $ctx $src $conf $ts $old_st)
             (progn
               (remove-atom &feedback_space (FeedbackRecord $id $cat $pol $tt $tid $txt $ctx $src $conf $ts $old_st))
               (add-atom &feedback_space (FeedbackRecord $id $cat $pol $tt $tid $txt $ctx $src $conf $ts $new_status))
               (FeedbackStatusUpdated $id $new_status)))
            ($_ (FeedbackNotFound $id)))))))

;; Clear feedback space
(= (feedback-clear)
   (progn
     (collapse (match &feedback_space $x (remove-atom &feedback_space $x)))
     (add-atom &feedback_space (FeedbackCounter 0))
     "Feedback space cleared."))
