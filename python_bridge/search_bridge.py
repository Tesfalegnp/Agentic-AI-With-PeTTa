"""
PeTTa Agentic AI Framework - Web Search Transport Bridge
Module: python_bridge/search_bridge.py

Stateless HTTP transport for web search providers (Brave Search, Tavily, and zero-config DuckDuckGo fallback).
PeTTa owns all search decision-making, query formation, result filtering, and synthesis.
"""

import os
import json
import re
import urllib.request
import urllib.parse
from typing import Dict, Any, List


def _sanitize_string(s: str) -> str:
    """Removes API keys or authorization headers if present in text."""
    if not isinstance(s, str):
        return ""
    s = re.sub(r'(AIza|sk-|Bearer\s+)[A-Za-z0-9_-]{16,}', '[REDACTED]', s)
    return s.strip()


def query_search(query: str, max_results: int = 3, timeout_seconds: int = 10) -> str:
    """
    Executes a web search query through the configured provider:
    1. Tavily Search (if TAVILY_API_KEY is present)
    2. Brave Search (if BRAVE_API_KEY is present)
    3. Zero-config fallback (DuckDuckGo HTML scraper)
    Returns a JSON string formatted with status, results: [{title, url, snippet}], and sources.
    """
    clean_query = _sanitize_string(query)
    if not clean_query:
        return json.dumps({
            "status": "error",
            "error": "Empty or invalid search query.",
            "results": []
        })

    tavily_key = os.environ.get("TAVILY_API_KEY")
    brave_key = os.environ.get("BRAVE_API_KEY")

    if tavily_key and tavily_key.strip():
        return _search_tavily(clean_query, tavily_key.strip(), max_results, timeout_seconds)
    elif brave_key and brave_key.strip():
        return _search_brave(clean_query, brave_key.strip(), max_results, timeout_seconds)
    else:
        return _search_duckduckgo(clean_query, max_results, timeout_seconds)


def _search_tavily(query: str, api_key: str, max_results: int, timeout: int) -> str:
    """Invokes Tavily Search API."""
    url = "https://api.tavily.com/search"
    payload = {
        "api_key": api_key,
        "query": query,
        "max_results": max(1, min(max_results, 5)),
        "include_answer": False
    }
    headers = {"Content-Type": "application/json"}
    req = urllib.request.Request(url, data=json.dumps(payload).encode("utf-8"), headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            results = []
            for item in data.get("results", [])[:max_results]:
                results.append({
                    "title": item.get("title", "No Title"),
                    "url": item.get("url", ""),
                    "snippet": item.get("content", "")[:300]
                })
            return json.dumps({
                "status": "success",
                "provider": "tavily",
                "query": query,
                "count": len(results),
                "results": results
            })
    except Exception as e:
        return json.dumps({
            "status": "error",
            "provider": "tavily",
            "error": _sanitize_string(str(e)),
            "results": []
        })


def _search_brave(query: str, api_key: str, max_results: int, timeout: int) -> str:
    """Invokes Brave Search API."""
    params = urllib.parse.urlencode({"q": query, "count": max(1, min(max_results, 5))})
    url = f"https://api.search.brave.com/res/v1/web/search?{params}"
    headers = {
        "Accept": "application/json",
        "X-Subscription-Token": api_key
    }
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            results = []
            web_results = data.get("web", {}).get("results", [])
            for item in web_results[:max_results]:
                results.append({
                    "title": item.get("title", "No Title"),
                    "url": item.get("url", ""),
                    "snippet": item.get("description", "")[:300]
                })
            return json.dumps({
                "status": "success",
                "provider": "brave",
                "query": query,
                "count": len(results),
                "results": results
            })
    except Exception as e:
        return json.dumps({
            "status": "error",
            "provider": "brave",
            "error": _sanitize_string(str(e)),
            "results": []
        })


def _search_duckduckgo(query: str, max_results: int, timeout: int) -> str:
    """Zero-config public web search fallback using DuckDuckGo HTML parser."""
    params = urllib.parse.urlencode({"q": query})
    url = f"https://html.duckduckgo.com/html/?{params}"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
    }
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            html = resp.read().decode("utf-8", errors="ignore")
            results = []
            # Extract links and snippets via regex
            links = re.findall(r'<a[^>]*class="result__url"[^>]*href="([^"]+)"', html)
            snippets = re.findall(r'<a[^>]*class="result__snippet[^>]*>(.*?)</a>', html, re.DOTALL)
            titles = re.findall(r'<a[^>]*class="result__a"[^>]*>(.*?)</a>', html, re.DOTALL)

            for i in range(min(len(titles), max_results)):
                raw_title = re.sub(r'<[^>]+>', '', titles[i]).strip()
                raw_snippet = re.sub(r'<[^>]+>', '', snippets[i]).strip() if i < len(snippets) else ""
                raw_url = links[i].strip() if i < len(links) else ""
                # Unwrap duckduckgo uddg redirects if present
                if "uddg=" in raw_url:
                    parsed_qs = urllib.parse.parse_qs(urllib.parse.urlparse(raw_url).query)
                    if "uddg" in parsed_qs:
                        raw_url = parsed_qs["uddg"][0]
                if not raw_url.startswith("http"):
                    raw_url = f"https://duckduckgo.com{raw_url}"

                results.append({
                    "title": raw_title or "Web Result",
                    "url": raw_url,
                    "snippet": raw_snippet[:300]
                })

            if not results:
                return json.dumps({
                    "status": "empty",
                    "provider": "duckduckgo_fallback",
                    "query": query,
                    "message": "No relevant search results found.",
                    "results": []
                })

            return json.dumps({
                "status": "success",
                "provider": "duckduckgo_fallback",
                "query": query,
                "count": len(results),
                "results": results
            })
    except Exception as e:
        return json.dumps({
            "status": "error",
            "provider": "duckduckgo_fallback",
            "error": _sanitize_string(str(e)),
            "results": []
        })


def format_search_observation(json_str: str) -> str:
    """Formats search results JSON into a readable text observation for the PeTTa agent."""
    try:
        data = json.loads(json_str)
        if data.get("status") == "error":
            return f"[Observation from tool web_search ERROR]: {data.get('error', 'Search failed.')}"
        if data.get("status") == "empty" or not data.get("results"):
            return f"[Observation from tool web_search]: No search results found for '{data.get('query', '')}'."

        lines = [f"Found {len(data['results'])} web search result(s) for '{data.get('query', '')}':"]
        for idx, res in enumerate(data["results"], 1):
            title = res.get("title", "Untitled")
            url = res.get("url", "No URL")
            snippet = res.get("snippet", "").replace("\n", " ").strip()
            lines.append(f"{idx}. [{title}]({url})\n   Summary: {snippet}")

        lines.append("Note: Source URLs must be cited when incorporating this evidence.")
        return "\n".join(lines)
    except Exception as e:
        return f"[Observation from tool web_search ERROR]: Failed to parse search output: {str(e)}"
