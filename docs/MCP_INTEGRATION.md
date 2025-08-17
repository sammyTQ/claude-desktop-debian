# MCP (Model Context Protocol) Integration Guide

This guide provides comprehensive instructions for setting up and using MCP servers with Claude Desktop on Linux.

## What is MCP?

Model Context Protocol (MCP) allows Claude Desktop to connect to external tools, APIs, and data sources through standardized server interfaces. This enables Claude to perform actions like file operations, web searches, database queries, and more.

## Configuration Location

MCP configuration is stored in: `~/.config/Claude/claude_desktop_config.json`

## Basic Configuration

### Minimal Configuration Example

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "@modelcontextprotocol/server-filesystem",
        "/home/user/Documents"
      ]
    }
  }
}
```

### Complete Configuration Example

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "@modelcontextprotocol/server-filesystem",
        "/home/user/Documents"
      ],
      "env": {
        "NODE_OPTIONS": "--max-old-space-size=4096"
      }
    },
    "brave-search": {
      "command": "npx",
      "args": [
        "@modelcontextprotocol/server-brave-search"
      ],
      "env": {
        "BRAVE_API_KEY": "your-api-key-here"
      }
    },
    "github": {
      "command": "npx",
      "args": [
        "@modelcontextprotocol/server-github"
      ],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "your-token-here"
      }
    }
  }
}
```

## Popular MCP Servers

### Official Servers

- **@modelcontextprotocol/server-filesystem**: File system operations
- **@modelcontextprotocol/server-brave-search**: Web search via Brave API
- **@modelcontextprotocol/server-github**: GitHub integration
- **@modelcontextprotocol/server-sqlite**: SQLite database operations
- **@modelcontextprotocol/server-postgres**: PostgreSQL database operations

### Installation Commands

```bash
# Install Node.js if not already installed
sudo apt update
sudo apt install nodejs npm

# Install MCP servers globally
npm install -g @modelcontextprotocol/server-filesystem
npm install -g @modelcontextprotocol/server-brave-search
npm install -g @modelcontextprotocol/server-github
npm install -g @modelcontextprotocol/server-sqlite
```

## Security Considerations

1. **Filesystem Access**: Be careful with filesystem server paths. Only grant access to directories you want Claude to modify.

2. **API Keys**: Store API keys securely. Consider using environment variables:
   ```bash
   echo 'export BRAVE_API_KEY="your-key"' >> ~/.bashrc
   echo 'export GITHUB_PERSONAL_ACCESS_TOKEN="your-token"' >> ~/.bashrc
   source ~/.bashrc
   ```

3. **Network Access**: Some MCP servers may require network access. Ensure your firewall settings are appropriate.

## Troubleshooting

### Check Configuration Syntax

Use the provided validation script:
```bash
./scripts/validate-mcp-config.sh
```

### Common Issues

1. **Server Not Found**: Ensure the MCP server is installed globally or provide the full path.
2. **Permission Denied**: Check file permissions for filesystem access.
3. **API Key Invalid**: Verify your API keys are correct and have proper permissions.

### Debug Mode

Add debug logging to your configuration:
```json
{
  "mcpServers": {
    "your-server": {
      "command": "npx",
      "args": ["your-server"],
      "env": {
        "DEBUG": "mcp*"
      }
    }
  }
}
```

### Log Locations

- Claude Desktop logs: `~/.config/Claude/logs/`
- Application logs: Check `~/claude-desktop-launcher.log`

## Custom MCP Servers

### Creating Your Own Server

See the official MCP documentation for creating custom servers:
- [MCP Python SDK](https://github.com/modelcontextprotocol/python-sdk)
- [MCP TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk)

### Server Template

A basic Python MCP server structure:
```python
from mcp.server import Server
from mcp.types import Tool

server = Server("my-custom-server")

@server.list_tools()
async def list_tools():
    return [
        Tool(
            name="my_tool",
            description="Description of what this tool does",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {"type": "string"}
                }
            }
        )
    ]

@server.call_tool()
async def call_tool(name: str, arguments: dict):
    if name == "my_tool":
        # Implement your tool logic here
        return {"result": "Tool executed successfully"}

if __name__ == "__main__":
    server.run()
```

## Best Practices

1. **Start Simple**: Begin with filesystem or search servers before moving to complex integrations.
2. **Test Incrementally**: Add one server at a time to isolate configuration issues.
3. **Monitor Performance**: Some servers may impact Claude Desktop performance.
4. **Regular Updates**: Keep MCP servers updated to the latest versions.
5. **Backup Configurations**: Keep backups of working configurations.

## Resources

- [Official MCP Documentation](https://modelcontextprotocol.io/)
- [MCP Server Registry](https://github.com/modelcontextprotocol/servers)
- [Claude Desktop MCP Guide](https://docs.anthropic.com/claude/docs/mcp)