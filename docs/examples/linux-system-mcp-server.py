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

# Import MCP types and server
try:
    from mcp.server import Server
    from mcp.types import Tool, TextContent
except ImportError:
    print("Error: MCP Python SDK not installed")
    print("Install with: pip install mcp")
    exit(1)

class LinuxSystemMCP:
    def __init__(self):
        self.server = Server("linux-system-tools")
        self.setup_tools()
    
    def setup_tools(self):
        """Define available tools"""
        
        @self.server.list_tools()
        async def list_tools():
            return [
                Tool(
                    name="get_system_info",
                    description="Get comprehensive Linux system information",
                    inputSchema={
                        "type": "object",
                        "properties": {},
                        "required": []
                    }
                ),
                Tool(
                    name="list_processes",
                    description="List running processes with memory and CPU usage",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "limit": {
                                "type": "integer",
                                "description": "Number of processes to show (default: 10)",
                                "default": 10
                            }
                        },
                        "required": []
                    }
                ),
                Tool(
                    name="check_disk_usage",
                    description="Check disk usage for all mounted filesystems",
                    inputSchema={
                        "type": "object",
                        "properties": {},
                        "required": []
                    }
                ),
                Tool(
                    name="get_network_info",
                    description="Get network interface information",
                    inputSchema={
                        "type": "object",
                        "properties": {},
                        "required": []
                    }
                ),
                Tool(
                    name="run_command",
                    description="Run a safe shell command (restricted to read-only operations)",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "command": {
                                "type": "string",
                                "description": "Command to run (limited to safe, read-only commands)"
                            }
                        },
                        "required": ["command"]
                    }
                )
            ]
        
        @self.server.call_tool()
        async def call_tool(name: str, arguments: dict):
            """Handle tool calls"""
            
            if name == "get_system_info":
                return await self.get_system_info()
            elif name == "list_processes":
                limit = arguments.get("limit", 10)
                return await self.list_processes(limit)
            elif name == "check_disk_usage":
                return await self.check_disk_usage()
            elif name == "get_network_info":
                return await self.get_network_info()
            elif name == "run_command":
                command = arguments.get("command", "")
                return await self.run_safe_command(command)
            else:
                raise ValueError(f"Unknown tool: {name}")
    
    async def get_system_info(self):
        """Get comprehensive system information"""
        info = {
            "timestamp": datetime.now().isoformat(),
            "hostname": platform.node(),
            "os": {
                "system": platform.system(),
                "release": platform.release(),
                "version": platform.version(),
                "machine": platform.machine(),
                "processor": platform.processor()
            },
            "python": {
                "version": platform.python_version(),
                "implementation": platform.python_implementation()
            }
        }
        
        # Add distribution information if available
        try:
            with open('/etc/os-release', 'r') as f:
                os_release = {}
                for line in f:
                    if '=' in line:
                        key, value = line.strip().split('=', 1)
                        os_release[key] = value.strip('"')
                info["distribution"] = os_release
        except:
            pass
        
        # Add memory information
        try:
            memory = psutil.virtual_memory()
            info["memory"] = {
                "total_gb": round(memory.total / (1024**3), 2),
                "available_gb": round(memory.available / (1024**3), 2),
                "percent_used": memory.percent
            }
        except:
            pass
        
        # Add CPU information
        try:
            info["cpu"] = {
                "cores": psutil.cpu_count(logical=False),
                "logical_cores": psutil.cpu_count(logical=True),
                "current_percent": psutil.cpu_percent(interval=1)
            }
        except:
            pass
        
        return [TextContent(
            type="text",
            text=f"System Information:\n{json.dumps(info, indent=2)}"
        )]
    
    async def list_processes(self, limit: int = 10):
        """List running processes"""
        try:
            processes = []
            for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
                try:
                    processes.append(proc.info)
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    pass
            
            # Sort by CPU usage
            processes.sort(key=lambda x: x.get('cpu_percent', 0), reverse=True)
            processes = processes[:limit]
            
            output = f"Top {limit} Processes by CPU Usage:\n"
            output += f"{'PID':<8} {'Name':<20} {'CPU%':<8} {'Memory%':<8}\n"
            output += "-" * 50 + "\n"
            
            for proc in processes:
                output += f"{proc['pid']:<8} {proc['name'][:19]:<20} {proc['cpu_percent']:<8.1f} {proc['memory_percent']:<8.1f}\n"
            
            return [TextContent(type="text", text=output)]
            
        except Exception as e:
            return [TextContent(type="text", text=f"Error listing processes: {str(e)}")]
    
    async def check_disk_usage(self):
        """Check disk usage for all mounted filesystems"""
        try:
            output = "Disk Usage:\n"
            output += f"{'Filesystem':<20} {'Size':<10} {'Used':<10} {'Available':<10} {'Use%':<6} {'Mounted on'}\n"
            output += "-" * 80 + "\n"
            
            for partition in psutil.disk_partitions():
                try:
                    usage = psutil.disk_usage(partition.mountpoint)
                    
                    size_gb = usage.total / (1024**3)
                    used_gb = usage.used / (1024**3)
                    free_gb = usage.free / (1024**3)
                    percent = (usage.used / usage.total) * 100
                    
                    output += f"{partition.device[:19]:<20} {size_gb:<10.1f} {used_gb:<10.1f} {free_gb:<10.1f} {percent:<6.1f} {partition.mountpoint}\n"
                    
                except PermissionError:
                    output += f"{partition.device[:19]:<20} {'N/A':<10} {'N/A':<10} {'N/A':<10} {'N/A':<6} {partition.mountpoint}\n"
            
            return [TextContent(type="text", text=output)]
            
        except Exception as e:
            return [TextContent(type="text", text=f"Error checking disk usage: {str(e)}")]
    
    async def get_network_info(self):
        """Get network interface information"""
        try:
            output = "Network Interfaces:\n"
            
            interfaces = psutil.net_if_addrs()
            stats = psutil.net_if_stats()
            
            for interface, addresses in interfaces.items():
                output += f"\n{interface}:\n"
                
                # Interface status
                if interface in stats:
                    stat = stats[interface]
                    output += f"  Status: {'UP' if stat.isup else 'DOWN'}\n"
                    output += f"  Speed: {stat.speed} Mbps\n"
                
                # Addresses
                for addr in addresses:
                    if addr.family.name == 'AF_INET':
                        output += f"  IPv4: {addr.address}\n"
                        if addr.netmask:
                            output += f"  Netmask: {addr.netmask}\n"
                    elif addr.family.name == 'AF_INET6':
                        output += f"  IPv6: {addr.address}\n"
                    elif addr.family.name == 'AF_PACKET':
                        output += f"  MAC: {addr.address}\n"
            
            return [TextContent(type="text", text=output)]
            
        except Exception as e:
            return [TextContent(type="text", text=f"Error getting network info: {str(e)}")]
    
    async def run_safe_command(self, command: str):
        """Run a safe shell command"""
        
        # Whitelist of safe commands
        safe_commands = [
            'ls', 'pwd', 'whoami', 'date', 'uptime', 'df', 'free',
            'uname', 'which', 'whereis', 'locate', 'find', 'grep',
            'cat', 'head', 'tail', 'wc', 'sort', 'uniq', 'cut',
            'ps', 'top', 'htop', 'netstat', 'ss', 'lsof',
            'systemctl status', 'journalctl', 'dmesg'
        ]
        
        # Extract the base command
        base_cmd = command.split()[0] if command.split() else ""
        
        # Check if command is safe
        is_safe = any(command.startswith(safe_cmd) for safe_cmd in safe_commands)
        
        if not is_safe:
            return [TextContent(
                type="text",
                text=f"Command '{command}' is not allowed. Only safe, read-only commands are permitted.\n"
                     f"Allowed commands: {', '.join(safe_commands)}"
            )]
        
        try:
            # Run the command with timeout
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=30,
                cwd=Path.home()
            )
            
            output = f"Command: {command}\n"
            output += f"Exit code: {result.returncode}\n\n"
            
            if result.stdout:
                output += f"Output:\n{result.stdout}\n"
            
            if result.stderr:
                output += f"Error:\n{result.stderr}\n"
            
            return [TextContent(type="text", text=output)]
            
        except subprocess.TimeoutExpired:
            return [TextContent(type="text", text=f"Command '{command}' timed out after 30 seconds")]
        except Exception as e:
            return [TextContent(type="text", text=f"Error running command: {str(e)}")]

async def main():
    """Main server function"""
    print("🐧 Linux System MCP Server starting...")
    print("📊 Provides system information and monitoring tools")
    print("🔧 Available tools: system_info, processes, disk_usage, network_info, run_command")
    
    mcp = LinuxSystemMCP()
    
    # Run the server
    async with mcp.server.stdio() as streams:
        await mcp.server.run(*streams)

if __name__ == "__main__":
    asyncio.run(main())