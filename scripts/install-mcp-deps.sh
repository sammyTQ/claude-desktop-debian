#!/bin/bash
set -euo pipefail

# Install MCP Dependencies
# Installs Python packages needed for MCP servers and our custom examples

echo "🐧 Installing MCP Dependencies for Linux"
echo "========================================"

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed"
    echo "Install with: sudo apt update && sudo apt install python3 python3-pip"
    exit 1
fi

# Check if pip is available
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 is required but not installed"
    echo "Install with: sudo apt install python3-pip"
    exit 1
fi

echo "✅ Python 3 found: $(python3 --version)"
echo "✅ pip3 found: $(pip3 --version)"
echo ""

# Install MCP Python SDK
echo "📦 Installing MCP Python SDK..."
if pip3 install --user mcp psutil; then
    echo "✅ MCP Python SDK installed successfully"
else
    echo "❌ Failed to install MCP Python SDK"
    echo "Try: pip3 install --user mcp psutil"
    exit 1
fi

# Check if Node.js is available for official MCP servers
echo ""
echo "📦 Checking Node.js availability..."
if command -v npm &> /dev/null; then
    echo "✅ Node.js and npm found: $(npm --version)"
    echo "You can install official MCP servers with npm"
    
    echo ""
    echo "To install common MCP servers:"
    echo "  npm install -g @modelcontextprotocol/server-filesystem"
    echo "  npm install -g @modelcontextprotocol/server-brave-search"
    echo "  npm install -g @modelcontextprotocol/server-github"
    echo "  npm install -g @modelcontextprotocol/server-sqlite"
    
else
    echo "⚠️  Node.js/npm not found"
    echo "Install with: sudo apt update && sudo apt install nodejs npm"
    echo "This is needed for official MCP servers"
fi

echo ""
echo "🎉 MCP dependencies setup complete!"
echo ""
echo "Next steps:"
echo "1. Use './scripts/setup-mcp-servers.sh install filesystem' to configure MCP servers"
echo "2. Use './scripts/validate-mcp-config.sh' to validate your configuration"
echo "3. See docs/MCP_INTEGRATION.md for detailed setup instructions"