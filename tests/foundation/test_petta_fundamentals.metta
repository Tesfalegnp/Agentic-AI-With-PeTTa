; ==============================================================================
; PeTTa Fundamentals Test Suite
; ==============================================================================

; --- Test A: Basic Function Definition & Invocation ---
(= (add-two $x $y) (+ $x $y))
!(println! "--- Running Test A: Basic Function Definition & Invocation ---")
!(test (add-two 15 25) 40)

; --- Test B: Variables and Pattern Matching ---
(= (match-category (item book $title)) (FoundBook $title))
(= (match-category (item tool $name)) (FoundTool $name))
!(println! "--- Running Test B: Variables and Pattern Matching ---")
!(test (match-category (item book "Metta Guide")) (FoundBook "Metta Guide"))
!(test (match-category (item tool "Calculator")) (FoundTool "Calculator"))

; --- Test C: Multiple Function Clauses (Pattern Matching on Atoms) ---
(= (classify-status active) "Status is Active")
(= (classify-status paused) "Status is Paused")
(= (classify-status stopped) "Status is Stopped")
!(println! "--- Running Test C: Multiple Function Clauses ---")
!(test (classify-status active) "Status is Active")
!(test (classify-status paused) "Status is Paused")
!(test (classify-status stopped) "Status is Stopped")

; --- Test D: Recursive Function Execution ---
(= (factorial $n) (if (<= $n 1) 1 (* $n (factorial (- $n 1)))))
!(println! "--- Running Test D: Recursive Function Execution ---")
!(test (factorial 5) 120)

; --- Test E: List Construction and Matching ---
(= (head-of-list $l) (car-atom $l))
(= (tail-of-list $l) (cdr-atom $l))
!(println! "--- Running Test E: List Construction and Matching ---")
!(test (head-of-list (10 20 30)) 10)
!(test (tail-of-list (10 20 30)) (20 30))

; --- Test F: Atom Addition ---
!(println! "--- Running Test F: Atom Addition ---")
!(add-atom &self (service "calculator" active))
!(add-atom &self (service "memory" active))
!(test (match &self (service "calculator" $status) $status) active)

; --- Test G: Atom Retrieval ---
!(println! "--- Running Test G: Atom Retrieval ---")
!(test (collapse (match &self (service $name active) $name)) ("calculator" "memory"))

; --- Test H: Atom Removal ---
!(println! "--- Running Test H: Atom Removal ---")
!(remove-atom &self (service "calculator" active))
!(test (match &self (service "calculator" $status) $status) (empty))
!(test (match &self (service "memory" $status) $status) active)

; --- Test I: Module Import ---
!(println! "--- Running Test I: Module Import ---")
!(import! &self "sample_import.metta")
!(test (imported-multiplier 6 7) 42)

; --- Test J: Independent AtomSpace Creation ---
!(println! "--- Running Test J: Independent AtomSpace Creation ---")
!(add-atom &custom_space (config timeout 15))
!(test (match &custom_space (config timeout $t) $t) 15)
!(test (match &self (config timeout $t) $t) (empty))

!(println! "ALL FUNDAMENTALS TESTS COMPLETED")
