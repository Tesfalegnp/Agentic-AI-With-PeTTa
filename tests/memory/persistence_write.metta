; ==============================================================================
; PROCESS A: AtomSpace Persistence Write
; ==============================================================================

!(println! "=== PROCESS A: Starting Persistence Write ===")

; Import official Prolog interop helper
!(import! &self (library lib_import))
!(import_prolog_functions_from_file "tests/memory/persistence_helper.pl" (write_atom_to_file clear_file))

; Reset files
!(clear_file "tests/memory/store_long_term.metta")
!(clear_file "tests/memory/store_episodic.metta")

; Step 1: Create test memory atoms in &long_term
!(println! "--- Step 1: Populating &long_term and &episodic ---")
!(add-atom &long_term (MemoryAtom "mem_001" "User prefers concise answers" 1700000001))
!(add-atom &long_term (MemoryAtom "mem_002" "Default tool timeout is 15s" 1700000002))

; Step 2: Create test event atom in &episodic
!(add-atom &episodic (EpisodicEvent "evt_001" "agent_initialized" "status_ok" 1700000010))
!(add-atom &episodic (EpisodicEvent "evt_002" "user_query_handled" "status_success" 1700000020))

; Step 3: Serialize atoms to disk files
!(println! "--- Step 2: Serializing atoms to disk ---")
!(write_atom_to_file "tests/memory/store_long_term.metta" (repr (MemoryAtom "mem_001" "User prefers concise answers" 1700000001)))
!(write_atom_to_file "tests/memory/store_long_term.metta" (repr (MemoryAtom "mem_002" "Default tool timeout is 15s" 1700000002)))

!(write_atom_to_file "tests/memory/store_episodic.metta" (repr (EpisodicEvent "evt_001" "agent_initialized" "status_ok" 1700000010)))
!(write_atom_to_file "tests/memory/store_episodic.metta" (repr (EpisodicEvent "evt_002" "user_query_handled" "status_success" 1700000020)))

!(println! "=== PROCESS A: Successfully serialized atoms to disk. Exiting. ===")
