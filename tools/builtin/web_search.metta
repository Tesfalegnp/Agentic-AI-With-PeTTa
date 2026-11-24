;; =============================================================================
;; Built-in Tool: web_search
;; Module: tools/builtin/web_search.metta
;; =============================================================================

!(import! &self (library lib_import))
!(import! &self "../../agent/tool_result.metta")
!(import! &self "../../python_bridge/search_bridge.py")

;; Runs web search query via Python search transport bridge
(= (run-web-search $args)
   (case $args
     ((($query $max_results)
       (let $raw_json (py-call (search_bridge.query_search $query $max_results))
         (let $obs (py-call (search_bridge.format_search_observation $raw_json))
           (make-tool-success web_search $obs))))
      (($query)
       (let $raw_json (py-call (search_bridge.query_search $query 3))
         (let $obs (py-call (search_bridge.format_search_observation $raw_json))
           (make-tool-success web_search $obs))))
      ($_ (make-tool-failure web_search "web_search requires a query string and optional max_results count.")))))
