;; =============================================================================
;; STAGE D - MILESTONE 12: Adaptation & Feedback Disk Persistence
;; Module: agent/adaptation_persistence.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import! &self "feedback_store.metta")
!(import! &self "adaptation_registry.metta")
!(import! &self "adaptation_history.metta")
!(import! &self "adaptation_evaluation.metta")

(= (feedback-file-path) "memory/adaptation/feedback_store.data")
(= (adaptation-file-path) "memory/adaptation/adaptation_store.data")
(= (adaptation-history-file-path) "memory/adaptation/adaptation_history.data")
(= (adaptation-eval-file-path) "memory/adaptation/adaptation_eval_store.data")

;; Save all feedback, adaptation rules, evaluation, and history atoms to disk
(= (adaptation-save-to-disk)
   (let* (($fb_count   (save_feedback_records (feedback-file-path) &feedback_space))
          ($adapt_count (save_adaptation_rules (adaptation-file-path) &adaptation_space))
          ($hist_count  (save_adaptation_history (adaptation-history-file-path) &adaptation_history))
          ($eval_count  (save_adaptation_evals (adaptation-eval-file-path) &adaptation_eval_space)))
     (AdaptationSaveSuccess (feedback $fb_count) (adaptations $adapt_count) (history $hist_count) (evals $eval_count))))

;; Load persisted records from disk into target AtomSpaces
(= (adaptation-load-from-disk)
   (let* (($fb_count   (load_feedback_records (feedback-file-path) &feedback_space))
          ($adapt_count (load_adaptation_rules (adaptation-file-path) &adaptation_space))
          ($hist_count  (load_adaptation_history (adaptation-history-file-path) &adaptation_history))
          ($eval_count  (load_adaptation_evals (adaptation-eval-file-path) &adaptation_eval_space)))
     (AdaptationLoadSuccess (feedback $fb_count) (adaptations $adapt_count) (history $hist_count) (evals $eval_count))))

;; Clear persisted adaptation files from disk
(= (adaptation-clear-disk)
   (progn
     (clear_adaptation_file (feedback-file-path))
     (clear_adaptation_file (adaptation-file-path))
     (clear_adaptation_file (adaptation-history-file-path))
     (clear_adaptation_file (adaptation-eval-file-path))
     "Adaptation disk storage cleared."))
