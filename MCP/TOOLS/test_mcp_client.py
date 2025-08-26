#!/usr/bin/env python3
"""
Test the MCP server endpoints
"""

import requests
import json

def test_mcp_endpoints():
    base_url = "http://localhost:5000"
    
    print("Testing MCP Server Endpoints")
    print("=" * 40)
    
    # Test status endpoint
    try:
        response = requests.get(f"{base_url}/status")
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            print(f"Response: {response.json()}")
        print()
    except requests.exceptions.ConnectionError:
        print("Server not running. Start with: python mcp_server.py")
        return
    
    # Test list test suites
    try:
        response = requests.get(f"{base_url}/tests")
        print(f"List Tests: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"Test Suites: {data['test_suites']}")
            print(f"Total Tests: {data['total_tests']}")
        print()
    except Exception as e:
        print(f"Error: {e}")
    
    # Test specific test suite
    try:
        response = requests.get(f"{base_url}/tests/interactive_apartment")
        print(f"Interactive Apartment Suite: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"Test Count: {data['test_count']}")
            print(f"Status: {data['current_status']}")
            print(f"Failing Tests: {data['failing_tests']}")
        print()
    except Exception as e:
        print(f"Error: {e}")
    
    # Test run command
    try:
        response = requests.get(f"{base_url}/tests/interactive_apartment/run")
        print(f"Run Command: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"Command: {data['run_command']}")
            print(f"Working Dir: {data['working_directory']}")
        print()
    except Exception as e:
        print(f"Error: {e}")
    
    # Test failing tests
    try:
        response = requests.get(f"{base_url}/tests/failing")
        print(f"Failing Tests: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"Failing Suites: {list(data.keys())}")
        print()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    test_mcp_endpoints()
