;; =============================================================================
;; STAGE C - MILESTONE 9: Memory Data Model and Types
;; Module: agent/memory_types.metta
;; =============================================================================

;; Categories allowlist: fact, preference, goal, project, episodic
(= (is-valid-memory-category $cat)
   (case $cat
     ((fact true)
      (preference true)
      (goal true)
      (project true)
      (episodic true)
      ($_ false))))

;; Default memory type per category
(= (get-default-type-for-category $cat)
   (case $cat
     ((fact semantic)
      (preference preference)
      (goal goal)
      (project semantic)
      (episodic episodic)
      ($_ semantic))))

;; Memory record constructor
(= (make-memory-record $id $cat $type $content $created $updated $src $prio $tags $status)
   (MemoryRecord $id $cat $type $content $created $updated $src $prio $tags $status))
