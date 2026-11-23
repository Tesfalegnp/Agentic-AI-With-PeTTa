; ==============================================================================
; PROCESS B: AtomSpace Persistence Read & Verification
; ==============================================================================

!(println! "=== PROCESS B: Starting Fresh Process for Persistence Verification ===")

; Verify spaces are initially clean and empty
!(println! "--- Verifying initial clean state in fresh process ---")
!(test (match &long_term (MemoryAtom $id $content $ts) ($id $content $ts)) (empty))
!(test (match &episodic (EpisodicEvent $id $name $status $ts) ($id $name $status $ts)) (empty))

; Restore memory into target spaces using import!
!(println! "--- Restoring &long_term from store_long_term.metta ---")
!(import! &long_term "store_long_term.metta")

!(println! "--- Restoring &episodic from store_episodic.metta ---")
!(import! &episodic "store_episodic.metta")

; Verify retrieved atoms match the exact values stored by Process A
!(println! "--- Querying restored &long_term memory atoms ---")
!(test (match &long_term (MemoryAtom "mem_001" $content $ts) ($content $ts))
       ("User prefers concise answers" 1700000001))
!(test (match &long_term (MemoryAtom "mem_002" $content $ts) ($content $ts))
       ("Default tool timeout is 15s" 1700000002))

!(println! "--- Querying restored &episodic event atoms ---")
!(test (match &episodic (EpisodicEvent "evt_001" $name $status $ts) ($name $status $ts))
       ("agent_initialized" "status_ok" 1700000010))
!(test (match &episodic (EpisodicEvent "evt_002" $name $status $ts) ($name $status $ts))
       ("user_query_handled" "status_success" 1700000020))

; Verify space isolation is preserved on restored data
!(println! "--- Verifying cross-space isolation of restored data ---")
!(test (match &long_term (EpisodicEvent $id $n $s $ts) ($id $n $s $ts)) (empty))
!(test (match &episodic (MemoryAtom $id $c $ts) ($id $c $ts)) (empty))

!(println! "=== PROCESS B: PERSISTENCE ACROSS RESTART VERIFIED SUCCESSFULLY ===")
