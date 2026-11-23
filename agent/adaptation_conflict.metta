;; =============================================================================
;; STAGE D - MILESTONE 12: Adaptation Conflict Detection & Priority Engine
;; Module: agent/adaptation_conflict.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import_prolog_function string_concat)
!(import_prolog_function check_instruction_adaptation_conflict)
!(import_prolog_function detect_adaptation_rule_conflicts_in_space)
!(import! &self "adaptation_types.metta")
!(import! &self "adaptation_registry.metta")

;; Check if current user query contradicts an adaptation rule's recommendation
(= (check-query-adaptation-conflict $query $recommendation)
   (let $raw (check_instruction_adaptation_conflict $query $recommendation)
     (case $raw
       (((conflict $msg) (InstructionConflict $msg))
        ((no_conflict $none) NoConflict)
        ($_ NoConflict)))))

;; Detect internal conflicts between active adaptation rules
(= (detect-internal-adaptation-conflicts)
   (detect_adaptation_rule_conflicts_in_space &adaptation_space))
