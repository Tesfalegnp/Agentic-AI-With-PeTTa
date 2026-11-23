; ==============================================================================
; Live Google Gemini API Integration Test via PeTTa
; Calls genuine Gemini API via Python Bridge and displays response
; ==============================================================================

!(println! "=== Starting Live Gemini API Integration Test ===")

; Import Python Bridge
!(import! &self "../../python_bridge/bridge.py")

(= (ask-live-gemini $prompt)
   (let* (($raw_json (py-call (bridge.query "gemini" $prompt)))
          ($success  (py-call (bridge.get_field $raw_json "success")))
          ($content  (repr (py-call (bridge.get_field $raw_json "content"))))
          ($err      (repr (py-call (bridge.get_field $raw_json "error")))))
     (if (== $success true)
         (GeminiSuccess $content)
         (GeminiError $err))))

!(println! "--- Sending Query: 'Explain Agentic AI in two sentences.' ---")
!(let $result (ask-live-gemini "Explain Agentic AI in two sentences.")
   (case $result
     (((GeminiSuccess $ans)
       (progn
         (println! "✅ Real Gemini Response Received:")
         (println! $ans)))
      ((GeminiError $reason)
       (progn
         (println! "❌ Gemini API Error:")
         (println! $reason))))))

!(println! "=== Live Gemini Integration Test Completed ===")
