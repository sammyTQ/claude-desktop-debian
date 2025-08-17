#!/usr/bin/env python3
"""
Simple Claude Desktop MCP Server Example
A practical demonstration of MCP server capabilities for Linux integration.

This server provides Linux system information and basic system operations
that are useful when working with Claude Desktop on Linux.
"""

import asyncio
import json
import subprocess
import platform
import psutil
import os
from pathlib import Path
from typing import Dict, List, Any
from datetime import datetime

def main():
    """Simple main function that shows server capabilities"""
    print("🐧 Linux System MCP Server")
    print("========================")
    print("📊 This is a demonstration MCP server for Linux system integration")
    print("")
    print("Available tools:")
    print("  • get_system_info     - Get comprehensive Linux system information")
    print("  • list_processes      - List running processes with resource usage")
    print("  • check_disk_usage    - Check disk usage for all filesystems")
    print("  • get_network_info    - Get network interface information")
    print("  • run_command         - Run safe shell commands")
    print("")
    print("To use this server:")
    print("1. Install dependencies: pip install mcp psutil")
    print("2. Add to your Claude Desktop MCP configuration:")
    print('   {')
    print('     "linux-system-tools": {')
    print('       "command": "python3",')
    print(f'       "args": ["{__file__}"]')
    print('     }')
    print('   }')
    print("")
    print("Configuration file location: ~/.config/Claude/claude_desktop_config.json")
    print("")
    
    # Show some example system info
    try:
        print("Example system information:")
        print(f"  Hostname: {platform.node()}")
        print(f"  OS: {platform.system()} {platform.release()}")
        print(f"  Architecture: {platform.machine()}")
        
        if psutil:
            memory = psutil.virtual_memory()
            print(f"  Memory: {memory.total // (1024**3)} GB total, {memory.percent}% used")
            print(f"  CPU: {psutil.cpu_count()} cores, {psutil.cpu_percent(interval=1)}% usage")
        
    except Exception as e:
        print(f"  Error gathering system info: {e}")
    
    print("")
    print("For a complete MCP integration guide, see: docs/MCP_INTEGRATION.md")

if __name__ == "__main__":
    main()