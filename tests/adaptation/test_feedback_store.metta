;; =============================================================================
;; STAGE D - MILESTONE 12: Unit Test Suite - Feedback Store
;; Test: tests/adaptation/test_feedback_store.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import! &self "../../agent/feedback_store.metta")

!(println! "=== Running Feedback Store Tests ===")

;; Test 1: Record valid explicit feedback
!(let $res (feedback-record verbosity negative answer none "Too long, be concise" "q1" explicit_user 1.0)
   (case $res
     (((FeedbackRecorded $id verbosity negative "Too long, be concise")
       (println! "Test 1 PASSED: Valid explicit feedback recorded."))
      ($_ (test false true)))))

;; Test 2: Record valid inferred feedback
!(let $res (feedback-record tool_usage positive tool calc "Used calculator correctly" "q2" inferred_signal 0.5)
   (case $res
     (((FeedbackRecorded $id tool_usage positive "Used calculator correctly")
       (println! "Test 2 PASSED: Valid inferred feedback recorded."))
      ($_ (test false true)))))

;; Test 3: Reject invalid category
!(let $res (feedback-record invalid_category positive answer none "text" "q3" explicit_user 1.0)
   (case $res
     (((FeedbackValidationFailed $err)
       (println! "Test 3 PASSED: Invalid category safely rejected."))
      ($_ (test false true)))))

;; Test 4: Reject invalid polarity
!(let $res (feedback-record verbosity invalid_polarity answer none "text" "q4" explicit_user 1.0)
   (case $res
     (((FeedbackValidationFailed $err)
       (println! "Test 4 PASSED: Invalid polarity safely rejected."))
      ($_ (test false true)))))

;; Test 5: Reject invalid confidence
!(let $res (feedback-record verbosity negative answer none "text" "q5" explicit_user 2.5)
   (case $res
     (((FeedbackValidationFailed $err)
       (println! "Test 5 PASSED: Invalid confidence (> 1.0) safely rejected."))
      ($_ (test false true)))))

;; Test 6: Duplicate feedback detection
!(let $dup_res (feedback-record verbosity negative answer none "Too long, be concise" "q1" explicit_user 1.0)
   (case $dup_res
     (((FeedbackDuplicate "fb_1")
       (println! "Test 6 PASSED: Duplicate feedback detected and rejected."))
      ($_ (test false true)))))

;; Test 7: Feedback retrieval by ID
!(let $fb (feedback-get "fb_1")
   (case $fb
     (((FeedbackRecord "fb_1" verbosity negative answer none "Too long, be concise" "q1" explicit_user 1.0 $ts active)
       (println! "Test 7 PASSED: Feedback retrieved successfully."))
      ($_ (test false true)))))

;; Test 8: Status update
!(let $up (feedback-update-status "fb_1" superseded)
   (case $up
     (((FeedbackStatusUpdated "fb_1" superseded)
       (let $fb_up (feedback-get "fb_1")
         (case $fb_up
           (((FeedbackRecord "fb_1" verbosity negative answer none "Too long, be concise" "q1" explicit_user 1.0 $ts superseded)
             (println! "Test 8 PASSED: Status updated to superseded."))
            ($_ (test false true))))))
      ($_ (test false true)))))

;; Reset and cleanup
!(feedback-clear)
!(println! "=== ALL FEEDBACK STORE TESTS PASSED ===")
