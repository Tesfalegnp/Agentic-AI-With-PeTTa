"""
Minimal Python Helper for PeTTa-Janus Interoperability Testing.
Exclusively implements deterministic test functions for Task 3.3.
"""

import json

def get_string():
    return "Hello from Python"

def get_integer():
    return 42

def get_float():
    return 3.14159

def get_boolean():
    return True

def echo_string(s):
    return f"Python received: {s}"

def add_integers(a, b):
    return a + b

def multiply_floats(x, y):
    return round(x * y, 4)

def get_normalized_json():
    payload = {
        "status": "success",
        "action": "use_tool",
        "tool_name": "calculator",
        "parameters": [10, 20]
    }
    return json.dumps(payload)

def raise_test_exception(msg):
    raise ValueError(f"Intentional test exception: {msg}")

def safe_divide(a, b):
    if b == 0:
        return "ERROR: Division by zero"
    return a / b
