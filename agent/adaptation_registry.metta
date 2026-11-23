;; =============================================================================
;; STAGE D - MILESTONE 12: Adaptation Rule Registry
;; Module: agent/adaptation_registry.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import! &self "feedback_store.metta")
!(import! &self "adaptation_types.metta")

!(bind! &adaptation_space (new-space))

;; Initialize counter
!(add-atom &adaptation_space (AdaptationCounter 0))

;; Next Adaptation ID generator
(= (adaptation-next-id)
   (let $c_atoms (collapse (match &adaptation_space (AdaptationCounter $c) $c))
     (let $current (if (== $c_atoms ()) 0 (car-atom $c_atoms))
       (let $next (+ $current 1)
         (progn
           (remove-atom &adaptation_space (AdaptationCounter $current))
           (add-atom &adaptation_space (AdaptationCounter $next))
           (string_concat "adapt_" (repr $next)))))))

;; Register a new candidate adaptation rule
(= (adaptation-create $category $description $trigger $recommendation $supporting_fbs $score $confidence)
   (let* (($aid (adaptation-next-id))
          ($now (get_adaptation_timestamp))
          ($rec (AdaptationRule $aid $category $description $trigger $recommendation $supporting_fbs $score $confidence $now $now candidate)))
     (progn
       (add-atom &adaptation_space $rec)
       (AdaptationCreated $aid $category $recommendation))))

;; Retrieve an adaptation rule by ID
(= (adaptation-get $id)
   (let $found (collapse (match &adaptation_space
                                (AdaptationRule $id $cat $desc $trig $rec $supp $score $conf $cr $up $st)
                                (AdaptationRule $id $cat $desc $trig $rec $supp $score $conf $cr $up $st)))
     (if (== $found ())
         (AdaptationNotFound $id)
         (car-atom $found))))

;; Update adaptation status
(= (adaptation-update-status $id $new_status)
   (if (== (is-valid-adaptation-status $new_status) false)
       (AdaptationStatusUpdateFailed (string_concat "Invalid adaptation status: " (repr $new_status)))
       (let $found (adaptation-get $id)
         (case $found
           (((AdaptationRule $id $cat $desc $trig $rec $supp $score $conf $cr $up $old_st)
             (let $now (get_adaptation_timestamp)
               (progn
                 (remove-atom &adaptation_space (AdaptationRule $id $cat $desc $trig $rec $supp $score $conf $cr $up $old_st))
                 (add-atom &adaptation_space (AdaptationRule $id $cat $desc $trig $rec $supp $score $conf $cr $now $new_status))
                 (AdaptationStatusUpdated $id $new_status))))
            ($_ (AdaptationNotFound $id)))))))

;; List adaptation rules by status ('all' lists everything)
(= (adaptation-list $status)
   (if (== $status all)
       (collapse (match &adaptation_space
                        (AdaptationRule $id $cat $desc $trig $rec $supp $score $conf $cr $up $st)
                        (AdaptationRule $id $cat $desc $trig $rec $supp $score $conf $cr $up $st)))
       (collapse (match &adaptation_space
                        (AdaptationRule $id $cat $desc $trig $rec $supp $score $conf $cr $up $status)
                        (AdaptationRule $id $cat $desc $trig $rec $supp $score $conf $cr $up $status)))))

;; Inspect adaptation rule details
(= (adaptation-inspect $id)
   (let $rule (adaptation-get $id)
     (case $rule
       (((AdaptationRule $id $cat $desc $trig $rec $supp $score $conf $cr $up $st)
         (AdaptationInspection $id $cat $desc $trig $rec $supp $score $conf $cr $up $st))
        ($_ (AdaptationNotFound $id))))))

;; Remove adaptation rule
(= (adaptation-remove $id)
   (let $found (adaptation-get $id)
     (case $found
       (((AdaptationRule $id $cat $desc $trig $rec $supp $score $conf $cr $up $st)
         (progn
           (remove-atom &adaptation_space (AdaptationRule $id $cat $desc $trig $rec $supp $score $conf $cr $up $st))
           (AdaptationRemoved $id)))
        ($_ (AdaptationNotFound $id))))))

;; Clear adaptation space
(= (adaptation-clear)
   (progn
     (collapse (match &adaptation_space $x (remove-atom &adaptation_space $x)))
     (add-atom &adaptation_space (AdaptationCounter 0))
     "Adaptation space cleared."))
