;; =============================================================================
;; STAGE D - MILESTONE 13: Web UI Feedback Gateway Entry Point
;; Module: agent/feedback_gateway.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "telemetry.metta")
!(import! &self "feedback_store.metta")
!(import! &self "feedback_aggregation.metta")
!(import! &self "adaptation_engine.metta")
!(import! &self "adaptation_evaluation.metta")
!(import! &self "adaptation_persistence.metta")

(= (run-ui-feedback-turn)
   (progn
     (adaptation-load-from-disk)
     (let ($cat $pol $type $id $text $rating) (read_session_feedback)
       (progn
         (emit-telemetry "feedback_received" "feedback" (string_concat "Received user feedback for " (repr $cat)) $text)
         (let $fb_res (feedback-record $cat $pol $type $id $text "ui_session" explicit_user $rating)
           (case $fb_res
             (((FeedbackRecorded $fbid $c $p $t)
               (progn
                 (emit-telemetry "feedback_stored" "feedback" "Feedback record stored in &feedback_space" (repr $fbid))
                 ;; Check if recurring pattern emerged
                 (let $has_pattern (feedback-has-recurring-pattern $cat)
                   (if (== $has_pattern true)
                       (emit-telemetry "adaptation_candidate" "adaptation" "Recurring feedback pattern detected" (repr $cat))
                       true))
                 (adaptation-save-to-disk)
                 (write-gateway-result "success" "feedback_recorded" (repr $fbid))
                 (println! (string_concat "Feedback Gateway: Recorded " (repr $fbid)))))

              ((FeedbackDuplicate $dup_id)
               (progn
                 (emit-telemetry "feedback_duplicate" "feedback" "Identical feedback already recorded" (repr $dup_id))
                 (write-gateway-result "success" "feedback_duplicate" (repr $dup_id))
                 (println! "Feedback Gateway: Duplicate ignored.")))

              ((FeedbackValidationFailed $reason)
               (progn
                 (emit-telemetry "feedback_error" "feedback" "Feedback validation failed" $reason)
                 (write-gateway-result "error" "validation_failed" $reason)
                 (println! (string_concat "Feedback Gateway: Validation failed - " $reason))))

              ($other
               (progn
                 (write-gateway-result "error" "unknown" (repr $other))
                 (println! "Feedback Gateway: Unknown outcome."))))))))))

!(run-ui-feedback-turn)
