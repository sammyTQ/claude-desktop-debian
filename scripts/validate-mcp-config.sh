#!/bin/bash
set -euo pipefail

# MCP Configuration Validator
# Validates Claude Desktop MCP configuration files

CONFIG_FILE="$HOME/.config/Claude/claude_desktop_config.json"
TEMP_DIR="/tmp/mcp-validation-$$"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Claude Desktop MCP Configuration Validator${NC}"
echo "==========================================="

# Check if configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}Warning: Configuration file not found at $CONFIG_FILE${NC}"
    echo "This is normal if you haven't set up MCP yet."
    echo ""
    echo "To get started, you can copy one of the example configurations:"
    echo "  mkdir -p ~/.config/Claude"
    echo "  cp docs/examples/basic-filesystem.json ~/.config/Claude/claude_desktop_config.json"
    echo ""
    echo "Then customize the paths and settings for your needs."
    exit 0
fi

echo -e "${BLUE}Found configuration file: $CONFIG_FILE${NC}"
echo ""

# Validate JSON syntax
echo "🔍 Validating JSON syntax..."
if ! python3 -m json.tool "$CONFIG_FILE" > /dev/null 2>&1; then
    echo -e "${RED}❌ Invalid JSON syntax in configuration file${NC}"
    echo "Please check your configuration file for syntax errors."
    
    # Try to show the error
    echo ""
    echo "JSON validation error:"
    python3 -m json.tool "$CONFIG_FILE" 2>&1 || true
    exit 1
fi
echo -e "${GREEN}✅ JSON syntax is valid${NC}"

# Create temporary directory for validation
mkdir -p "$TEMP_DIR"
trap "rm -rf $TEMP_DIR" EXIT

# Extract and validate MCP servers configuration
echo ""
echo "🔍 Validating MCP servers configuration..."

# Check if mcpServers section exists
if ! jq -e '.mcpServers' "$CONFIG_FILE" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  No mcpServers section found in configuration${NC}"
    echo "Add an mcpServers section to enable MCP functionality."
    exit 0
fi

# Get list of configured servers
SERVERS=$(jq -r '.mcpServers | keys[]' "$CONFIG_FILE" 2>/dev/null || echo "")

if [ -z "$SERVERS" ]; then
    echo -e "${YELLOW}⚠️  No MCP servers configured${NC}"
    exit 0
fi

echo "Found MCP servers: $(echo $SERVERS | tr '\n' ' ')"
echo ""

# Validate each server
TOTAL_SERVERS=0
VALID_SERVERS=0

for server in $SERVERS; do
    echo "🔍 Validating server: $server"
    TOTAL_SERVERS=$((TOTAL_SERVERS + 1))
    
    # Extract server configuration
    jq -r ".mcpServers.$server" "$CONFIG_FILE" > "$TEMP_DIR/server_config.json"
    
    # Check required fields
    COMMAND=$(jq -r '.command // empty' "$TEMP_DIR/server_config.json")
    ARGS=$(jq -r '.args // empty' "$TEMP_DIR/server_config.json")
    
    if [ -z "$COMMAND" ]; then
        echo -e "  ${RED}❌ Missing 'command' field${NC}"
        continue
    fi
    
    # Check if command exists
    if ! command -v "$COMMAND" &> /dev/null; then
        echo -e "  ${YELLOW}⚠️  Command '$COMMAND' not found in PATH${NC}"
        echo "     You may need to install it or provide the full path"
    else
        echo -e "  ${GREEN}✅ Command '$COMMAND' found${NC}"
    fi
    
    # Validate args if they exist
    if [ "$ARGS" != "null" ] && [ -n "$ARGS" ]; then
        ARG_COUNT=$(jq -r '.args | length' "$TEMP_DIR/server_config.json")
        echo -e "  ${GREEN}✅ Args configured ($ARG_COUNT arguments)${NC}"
    fi
    
    # Check environment variables
    ENV_VARS=$(jq -r '.env // {}' "$TEMP_DIR/server_config.json")
    if [ "$ENV_VARS" != "{}" ]; then
        ENV_COUNT=$(jq -r '.env | length' "$TEMP_DIR/server_config.json")
        echo -e "  ${GREEN}✅ Environment variables configured ($ENV_COUNT variables)${NC}"
        
        # Check for placeholder values
        if jq -r '.env | values[]' "$TEMP_DIR/server_config.json" | grep -q "your-.*-here"; then
            echo -e "  ${YELLOW}⚠️  Found placeholder values in environment variables${NC}"
            echo "     Remember to replace these with actual values"
        fi
    fi
    
    VALID_SERVERS=$((VALID_SERVERS + 1))
    echo -e "  ${GREEN}✅ Server configuration is valid${NC}"
    echo ""
done

# Summary
echo "📊 Validation Summary"
echo "===================="
echo "Total servers configured: $TOTAL_SERVERS"
echo "Valid configurations: $VALID_SERVERS"

if [ $VALID_SERVERS -eq $TOTAL_SERVERS ] && [ $TOTAL_SERVERS -gt 0 ]; then
    echo -e "${GREEN}🎉 All MCP server configurations are valid!${NC}"
else
    echo -e "${YELLOW}⚠️  Some configurations may need attention${NC}"
fi

echo ""
echo "💡 Tips:"
echo "   - Test your configuration by restarting Claude Desktop"
echo "   - Check logs at ~/.config/Claude/logs/ if servers don't work"
echo "   - Use 'npx <server-package>' manually to test server installation"

echo ""
echo "📖 For more help, see: docs/MCP_INTEGRATION.md"