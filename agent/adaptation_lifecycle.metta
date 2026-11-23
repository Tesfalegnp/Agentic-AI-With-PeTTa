;; =============================================================================
;; STAGE D - MILESTONE 12: Adaptation Rule Lifecycle Engine
;; Module: agent/adaptation_lifecycle.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "adaptation_types.metta")
!(import! &self "adaptation_registry.metta")
!(import! &self "adaptation_validator.metta")

;; Activate a candidate or suspended rule after validation
(= (adaptation-activate $id)
   (let $val (validate-adaptation-rule $id)
     (case $val
       (((AdaptationValidationSuccess $id)
         (let $res (adaptation-update-status $id active)
           (case $res
             (((AdaptationStatusUpdated $id active) (AdaptationActivated $id))
              ($_ (AdaptationActivationFailed (string_concat "Failed to update status for: " $id)))))))
        ((AdaptationValidationFailed $reason)
         (AdaptationActivationFailed $reason))))))

;; Suspend an active rule (e.g. on ambiguity or review)
(= (adaptation-suspend $id)
   (let $res (adaptation-update-status $id suspended)
     (case $res
       (((AdaptationStatusUpdated $id suspended) (AdaptationSuspended $id))
        ($_ (AdaptationSuspensionFailed $id))))))

;; Disable an active or candidate rule (user-controlled shutdown)
(= (adaptation-disable $id)
   (let $res (adaptation-update-status $id disabled)
     (case $res
       (((AdaptationStatusUpdated $id disabled) (AdaptationDisabled $id))
        ($_ (AdaptationDisableFailed $id))))))

;; Supersede an outdated rule with a new rule
(= (adaptation-supersede $old_id $new_id)
   (let $act (adaptation-activate $new_id)
     (case $act
       (((AdaptationActivated $new_id)
         (progn
           (adaptation-update-status $old_id superseded)
           (AdaptationSuperseded $old_id $new_id)))
        ((AdaptationActivationFailed $reason)
         (AdaptationSupersedeFailed $reason))))))

;; Restore a suspended or disabled rule
(= (adaptation-restore $id)
   (let $val (validate-adaptation-rule $id)
     (case $val
       (((AdaptationValidationSuccess $id)
         (adaptation-update-status $id active))
        ((AdaptationValidationFailed $reason)
         (AdaptationRestoreFailed $reason))))))
