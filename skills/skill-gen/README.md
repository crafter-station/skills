# skill-gen

Auto-generate Claude skills from documentation using Firecrawl agent.

## What It Does

Point it at any documentation and get a working skill with:
- SKILL.md with proper frontmatter
- references/ folder with extracted patterns
- Ready to use with Claude Code, Cursor, Copilot

## Installation

```bash
npx skills add crafter-station/skills --skill skill-gen -g
```

## Requirements

1. **Firecrawl API Key**: Sign up at [firecrawl.dev](https://firecrawl.dev)
   - Free tier: 5 daily agent runs
   - Each skill generation: 5-15 credits (mini) or 15-50 credits (pro)

2. **Firecrawl MCP Server**: Install from [mendableai/firecrawl-mcp](https://github.com/mendableai/firecrawl-mcp)

3. **MCP Configuration**: Add to `~/.config/claude/claude_desktop_config.json`:
   ```json
   {
     "mcpServers": {
       "firecrawl": {
         "command": "npx",
         "args": ["-y", "@mendable/firecrawl-mcp"],
         "env": {
           "FIRECRAWL_API_KEY": "your-api-key-here"
         }
       }
     }
   }
   ```

## Usage

Ask Claude to research docs or pass a URL directly:

```
"Research Stripe webhooks and create a skill"
```

```
"Create a skill from stripe.com/docs/webhooks"
```

Claude will:
1. Ask 3 clarifying questions (focus areas, use cases, workflows)
2. Use Firecrawl agent to extract structured content
3. Generate SKILL.md with frontmatter + instructions
4. Create references/ with patterns, examples, schemas

## Examples

Used to scaffold Clerk skills:
- clerk-webhooks - Webhook patterns
- clerk-orgs - Multi-tenant setup
- clerk-custom-ui - Component customization

**Note**: The generated skills are starting points. You still need to review and refine with critical thinking. But it beats writing from scratch.

## Credits

Built by [Railly Hugo](https://railly.dev) for [Crafter Station](https://crafterstation.com).

Uses [Firecrawl](https://firecrawl.dev) agent endpoint for structured extraction.
