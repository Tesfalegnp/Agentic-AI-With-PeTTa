; ==============================================================================
; PeTTa - Python Interoperability Test Suite (Janus py-call)
; ==============================================================================

; --- Import Python Helper Module ---
!(println! "--- Importing interop_helper.py ---")
!(import! &self "interop_helper.py")

; --- Test 1: Python returning string ---
!(println! "--- Test 1: Python returning string ---")
!(test (repr (py-call (interop_helper.get_string))) "Hello from Python")

; --- Test 2: Python returning integer ---
!(println! "--- Test 2: Python returning integer ---")
!(test (py-call (interop_helper.get_integer)) 42)

; --- Test 3: Python returning float ---
!(println! "--- Test 3: Python returning float ---")
!(test (py-call (interop_helper.get_float)) 3.14159)

; --- Test 4: Python returning boolean ---
!(println! "--- Test 4: Python returning boolean ---")
!(test (py-call (interop_helper.get_boolean)) true)

; --- Test 5: PeTTa passing string to Python ---
!(println! "--- Test 5: PeTTa passing string to Python ---")
!(test (repr (py-call (interop_helper.echo_string "PeTTa input string"))) "Python received: PeTTa input string")

; --- Test 6: PeTTa passing integers to Python ---
!(println! "--- Test 6: PeTTa passing integers to Python ---")
!(test (py-call (interop_helper.add_integers 100 250)) 350)

; --- Test 7: PeTTa passing floats to Python ---
!(println! "--- Test 7: PeTTa passing floats to Python ---")
!(test (py-call (interop_helper.multiply_floats 2.5 4.0)) 10.0)

; --- Test 8: Python returning normalized JSON string ---
!(println! "--- Test 8: Python returning normalized JSON string ---")
!(let $json_str (repr (py-call (interop_helper.get_normalized_json)))
      (println! (concat "Retrieved JSON: " $json_str)))

; --- Test 9 & 10: Exception Handling & Safe Recovery ---
!(println! "--- Test 9 & 10: Exception Handling & Safe Recovery ---")
!(test (py-call (interop_helper.safe_divide 50 2)) 25.0)
!(test (repr (py-call (interop_helper.safe_divide 50 0))) "ERROR: Division by zero")

; --- Repeated Python calls in one PeTTa process ---
!(println! "--- Repeated Calls Verification ---")
!(test (+ (py-call (interop_helper.add_integers 10 20)) (py-call (interop_helper.add_integers 30 40))) 100)

!(println! "ALL PYTHON INTEROPERABILITY TESTS COMPLETED")
