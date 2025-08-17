#!/bin/bash
set -euo pipefail

# MCP Server Setup Helper
# Helps users install and configure popular MCP servers

CONFIG_FILE="$HOME/.config/Claude/claude_desktop_config.json"
BACKUP_DIR="$HOME/.config/Claude/backups"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

show_usage() {
    echo -e "${BLUE}Claude Desktop MCP Server Setup Helper${NC}"
    echo "====================================="
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  install <server>    Install and configure an MCP server"
    echo "  list               List available MCP servers"
    echo "  status             Show current configuration status"
    echo "  backup             Backup current configuration"
    echo "  restore            Restore from backup"
    echo ""
    echo "Available servers:"
    echo "  filesystem         File system operations"
    echo "  brave-search       Web search via Brave API"
    echo "  github             GitHub integration"
    echo "  sqlite             SQLite database operations"
    echo "  postgres           PostgreSQL database operations"
    echo ""
    echo "Examples:"
    echo "  $0 install filesystem"
    echo "  $0 install brave-search"
    echo "  $0 status"
}

backup_config() {
    if [ -f "$CONFIG_FILE" ]; then
        mkdir -p "$BACKUP_DIR"
        BACKUP_FILE="$BACKUP_DIR/claude_desktop_config_$(date +%Y%m%d_%H%M%S).json"
        cp "$CONFIG_FILE" "$BACKUP_FILE"
        echo -e "${GREEN}✅ Configuration backed up to: $BACKUP_FILE${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  No configuration file found to backup${NC}"
        return 1
    fi
}

create_base_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << 'EOF'
{
  "mcpServers": {}
}
EOF
    echo -e "${GREEN}✅ Created base configuration file${NC}"
}

install_filesystem_server() {
    echo -e "${CYAN}Installing filesystem MCP server...${NC}"
    
    # Install the server
    if ! npm install -g @modelcontextprotocol/server-filesystem; then
        echo -e "${RED}❌ Failed to install filesystem server${NC}"
        return 1
    fi
    
    # Get user's Documents directory
    DOCS_DIR="$HOME/Documents"
    if [ ! -d "$DOCS_DIR" ]; then
        DOCS_DIR="$HOME"
    fi
    
    echo "Default filesystem path will be: $DOCS_DIR"
    read -p "Enter custom path (or press Enter to use default): " CUSTOM_PATH
    
    if [ -n "$CUSTOM_PATH" ]; then
        DOCS_DIR="$CUSTOM_PATH"
    fi
    
    # Ensure the directory exists
    mkdir -p "$DOCS_DIR"
    
    # Add to configuration
    add_server_to_config "filesystem" '{
  "command": "npx",
  "args": [
    "@modelcontextprotocol/server-filesystem",
    "'"$DOCS_DIR"'"
  ],
  "env": {
    "NODE_OPTIONS": "--max-old-space-size=4096"
  }
}'
    
    echo -e "${GREEN}✅ Filesystem server configured for: $DOCS_DIR${NC}"
}

install_brave_search_server() {
    echo -e "${CYAN}Installing Brave Search MCP server...${NC}"
    
    # Install the server
    if ! npm install -g @modelcontextprotocol/server-brave-search; then
        echo -e "${RED}❌ Failed to install Brave Search server${NC}"
        return 1
    fi
    
    echo "To use Brave Search, you need a Brave Search API key."
    echo "Get one at: https://brave.com/search/api/"
    echo ""
    read -p "Enter your Brave API key (or press Enter to configure later): " API_KEY
    
    if [ -z "$API_KEY" ]; then
        API_KEY="your-brave-api-key-here"
        echo -e "${YELLOW}⚠️  Remember to replace the placeholder API key in your configuration${NC}"
    fi
    
    # Add to configuration
    add_server_to_config "brave-search" '{
  "command": "npx",
  "args": [
    "@modelcontextprotocol/server-brave-search"
  ],
  "env": {
    "BRAVE_API_KEY": "'"$API_KEY"'"
  }
}'
    
    echo -e "${GREEN}✅ Brave Search server configured${NC}"
}

install_github_server() {
    echo -e "${CYAN}Installing GitHub MCP server...${NC}"
    
    # Install the server
    if ! npm install -g @modelcontextprotocol/server-github; then
        echo -e "${RED}❌ Failed to install GitHub server${NC}"
        return 1
    fi
    
    echo "To use GitHub integration, you need a Personal Access Token."
    echo "Create one at: https://github.com/settings/tokens"
    echo ""
    read -p "Enter your GitHub token (or press Enter to configure later): " TOKEN
    
    if [ -z "$TOKEN" ]; then
        TOKEN="your-github-token-here"
        echo -e "${YELLOW}⚠️  Remember to replace the placeholder token in your configuration${NC}"
    fi
    
    # Add to configuration
    add_server_to_config "github" '{
  "command": "npx",
  "args": [
    "@modelcontextprotocol/server-github"
  ],
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "'"$TOKEN"'"
  }
}'
    
    echo -e "${GREEN}✅ GitHub server configured${NC}"
}

install_sqlite_server() {
    echo -e "${CYAN}Installing SQLite MCP server...${NC}"
    
    # Install the server
    if ! npm install -g @modelcontextprotocol/server-sqlite; then
        echo -e "${RED}❌ Failed to install SQLite server${NC}"
        return 1
    fi
    
    # Get database path
    DEFAULT_DB="$HOME/databases/my-database.db"
    echo "Default database path: $DEFAULT_DB"
    read -p "Enter database path (or press Enter to use default): " DB_PATH
    
    if [ -z "$DB_PATH" ]; then
        DB_PATH="$DEFAULT_DB"
    fi
    
    # Ensure directory exists
    mkdir -p "$(dirname "$DB_PATH")"
    
    # Add to configuration
    add_server_to_config "sqlite" '{
  "command": "npx",
  "args": [
    "@modelcontextprotocol/server-sqlite",
    "'"$DB_PATH"'"
  ]
}'
    
    echo -e "${GREEN}✅ SQLite server configured for: $DB_PATH${NC}"
}

add_server_to_config() {
    local server_name="$1"
    local server_config="$2"
    
    # Ensure config file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        create_base_config
    fi
    
    # Backup current config
    backup_config
    
    # Add server to configuration using jq
    local temp_file=$(mktemp)
    jq ".mcpServers[\"$server_name\"] = $server_config" "$CONFIG_FILE" > "$temp_file"
    mv "$temp_file" "$CONFIG_FILE"
    
    echo -e "${GREEN}✅ Added $server_name to configuration${NC}"
}

show_status() {
    echo -e "${BLUE}Current MCP Configuration Status${NC}"
    echo "==============================="
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${YELLOW}⚠️  No configuration file found${NC}"
        echo "Run '$0 install <server>' to get started"
        return
    fi
    
    echo "Configuration file: $CONFIG_FILE"
    echo ""
    
    # Check if mcpServers exists
    if ! jq -e '.mcpServers' "$CONFIG_FILE" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  No mcpServers section found${NC}"
        return
    fi
    
    # List configured servers
    local servers=$(jq -r '.mcpServers | keys[]' "$CONFIG_FILE" 2>/dev/null || echo "")
    
    if [ -z "$servers" ]; then
        echo -e "${YELLOW}⚠️  No MCP servers configured${NC}"
        return
    fi
    
    echo -e "${GREEN}Configured servers:${NC}"
    for server in $servers; do
        local command=$(jq -r ".mcpServers.$server.command" "$CONFIG_FILE")
        echo "  • $server (command: $command)"
    done
    
    echo ""
    echo "Run './scripts/validate-mcp-config.sh' for detailed validation"
}

list_servers() {
    echo -e "${BLUE}Available MCP Servers${NC}"
    echo "===================="
    echo ""
    echo -e "${GREEN}filesystem${NC}          - File system operations"
    echo "                      Install: npm install -g @modelcontextprotocol/server-filesystem"
    echo ""
    echo -e "${GREEN}brave-search${NC}        - Web search via Brave API"
    echo "                      Install: npm install -g @modelcontextprotocol/server-brave-search"
    echo "                      Requires: Brave Search API key"
    echo ""
    echo -e "${GREEN}github${NC}              - GitHub integration"
    echo "                      Install: npm install -g @modelcontextprotocol/server-github"
    echo "                      Requires: GitHub Personal Access Token"
    echo ""
    echo -e "${GREEN}sqlite${NC}              - SQLite database operations"
    echo "                      Install: npm install -g @modelcontextprotocol/server-sqlite"
    echo ""
    echo -e "${GREEN}postgres${NC}            - PostgreSQL database operations"
    echo "                      Install: npm install -g @modelcontextprotocol/server-postgres"
    echo "                      Requires: PostgreSQL connection string"
}

# Main command processing
case "${1:-}" in
    "install")
        if [ $# -lt 2 ]; then
            echo "Error: Please specify a server to install"
            echo "Usage: $0 install <server>"
            exit 1
        fi
        
        SERVER="$2"
        case "$SERVER" in
            "filesystem")
                install_filesystem_server
                ;;
            "brave-search")
                install_brave_search_server
                ;;
            "github")
                install_github_server
                ;;
            "sqlite")
                install_sqlite_server
                ;;
            "postgres")
                echo "PostgreSQL server setup not implemented yet"
                echo "Please see docs/examples/database-servers.json for manual setup"
                ;;
            *)
                echo "Error: Unknown server '$SERVER'"
                echo "Run '$0 list' to see available servers"
                exit 1
                ;;
        esac
        
        echo ""
        echo -e "${GREEN}🎉 Setup complete!${NC}"
        echo "Restart Claude Desktop to use the new server."
        ;;
    "list")
        list_servers
        ;;
    "status")
        show_status
        ;;
    "backup")
        backup_config
        ;;
    "restore")
        echo "Restore functionality not implemented yet"
        echo "Backups are stored in: $BACKUP_DIR"
        ;;
    "-h"|"--help"|"help"|"")
        show_usage
        ;;
    *)
        echo "Error: Unknown command '$1'"
        show_usage
        exit 1
        ;;
esac