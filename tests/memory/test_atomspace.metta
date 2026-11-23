; ==============================================================================
; PeTTa AtomSpace Isolation & Independence Test Suite
; ==============================================================================

!(println! "=== Starting AtomSpace Isolation Test ===")

; --- Step 1: Add distinct atoms to all three spaces ---
!(println! "--- Step 1: Adding distinct atoms to &short_term, &long_term, &episodic ---")
!(add-atom &short_term (Goal "calculate word count"))
!(add-atom &short_term (CurrentStep 2))

!(add-atom &long_term (UserPreference "output_format" "markdown"))
!(add-atom &long_term (UserPreference "language" "python"))

!(add-atom &episodic (SessionLog "session_001" "completed" 100))
!(add-atom &episodic (SessionLog "session_002" "failed" 50))

; --- Step 2 & 3: Retrieve atoms and verify complete cross-space isolation ---
!(println! "--- Step 2 & 3: Verifying cross-space isolation ---")

; Verify &short_term has its atoms
!(test (match &short_term (Goal $g) $g) "calculate word count")
!(test (match &short_term (CurrentStep $s) $s) 2)

; Verify &short_term DOES NOT have &long_term or &episodic atoms
!(test (match &short_term (UserPreference $k $v) ($k $v)) (empty))
!(test (match &short_term (SessionLog $id $status $cost) ($id $status $cost)) (empty))

; Verify &long_term has its atoms
!(test (match &long_term (UserPreference "output_format" $v) $v) "markdown")
!(test (match &long_term (UserPreference "language" $v) $v) "python")

; Verify &long_term DOES NOT have &short_term or &episodic atoms
!(test (match &long_term (Goal $g) $g) (empty))
!(test (match &long_term (SessionLog $id $status $cost) ($id $status $cost)) (empty))

; Verify &episodic has its atoms
!(test (match &episodic (SessionLog "session_001" $status $cost) ($status $cost)) ("completed" 100))
!(test (match &episodic (SessionLog "session_002" $status $cost) ($status $cost)) ("failed" 50))

; Verify &episodic DOES NOT have &short_term or &long_term atoms
!(test (match &episodic (Goal $g) $g) (empty))
!(test (match &episodic (UserPreference $k $v) ($k $v)) (empty))

; --- Step 4: Update an atom in &short_term ---
!(println! "--- Step 4: Updating atom in &short_term (Step 2 -> Step 3) ---")
!(remove-atom &short_term (CurrentStep 2))
!(add-atom &short_term (CurrentStep 3))
!(test (match &short_term (CurrentStep $s) $s) 3)

; --- Step 5 & 6: Remove an atom and verify it affects ONLY intended space ---
!(println! "--- Step 5 & 6: Removing session_002 from &episodic ---")
!(remove-atom &episodic (SessionLog "session_002" "failed" 50))
!(test (match &episodic (SessionLog "session_002" $status $cost) ($status $cost)) (empty))
; Verify session_001 in &episodic is still present
!(test (match &episodic (SessionLog "session_001" $status $cost) ($status $cost)) ("completed" 100))
; Verify &long_term and &short_term are completely unaffected
!(test (match &short_term (CurrentStep $s) $s) 3)
!(test (match &long_term (UserPreference "output_format" $v) $v) "markdown")

; --- Step 7: Pattern matching and variable binding ---
!(println! "--- Step 7: Pattern matching on multiple long-term preferences ---")
(= (get-preferences)
   (collapse (match &long_term (UserPreference $k $v) (pref $k $v))))
!(test (get-preferences) ((pref "output_format" "markdown") (pref "language" "python")))

!(println! "ALL ATOMSPACE ISOLATION TESTS COMPLETED SUCCESSFULLY")
