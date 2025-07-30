# Claude Configuration

This directory contains the global Claude configuration that syncs across machines.

## Structure

- `CLAUDE.md` - Main Claude configuration with SoloClaude identity and workflows
- `MCP.md` - MCP server configuration and rules
- `PERSONAS.md` - Different Claude personas for various contexts
- `RULES.md` - Core rules and behavior patterns
- `settings.local.json` - Local Claude settings
- `shared/` - Shared configuration files referenced by CLAUDE.md
  - `soloclaude-identity.yml` - Core identity and directives
  - `soloclaude-workflows.yml` - Workflow engine configuration
  - `soloclaude-essentials.yml` - Essential systems and standards
  - `soloclaude-mcp.yml` - MCP integration rules
  - `soloclaude-repositories.yml` - Repository configurations
  - `solo-execution-rules.yml` - Solo server execution rules
  - `soloclaude-automation-scoring.yml` - Automation confidence scoring
  - `ticket-completion-process.yml` - Ticket workflow process
- `commands/` - Custom command definitions
- `projects/` - Project-specific configurations

## Installation

This configuration is automatically symlinked when running the dotfiles installer:

```bash
# From the dotfiles directory
stow claude
```

This will create symlinks:
- `~/.claude` → `/path/to/dotfiles/claude/.claude`

## Syncing Between Machines

1. Commit any changes to the dotfiles repository
2. Pull on the other machine
3. The symlinks will automatically use the updated configuration

## Adding New Configurations

To add new Claude configurations:

1. Add files to the appropriate directory in `~/.dotfiles/claude/.claude/`
2. Commit and push the changes
3. Pull on other machines to sync

## Notes

- The `.credentials.json` file is NOT synced for security reasons
- Machine-specific settings should go in `settings.local.json`
- Global configurations that should sync go in this directory