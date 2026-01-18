# Crafter Station Skills

Agent Skills for Claude Code, Cursor, Copilot, and other AI coding assistants.

**Philosophy**: Skills that work. Battle-tested patterns from production codebases.

## Available Skills

### Context Engineering

| Skill | Description |
|-------|-------------|
| [intent-layer](./context-engineering/intent-layer/) | Set up hierarchical AGENTS.md infrastructure so agents navigate codebases like senior engineers |

### Coming Soon

- **model-router** - Cost-aware model routing (Haiku/Sonnet/Opus)
- **daily-log** - Auto-logging commits and agent runs
- **parallel-agents** - Overnight builds with multiple agents
- **v0-prompt-framework** - Vercel's 3-input prompting method

## Installation

### Quick Install (Recommended)

```bash
# Install all skills globally
npx skills add crafter-station/skills -g

# Or install a specific skill
npx skills add crafter-station/skills --skill intent-layer -g
```

Works with Claude Code, Codex, Cursor, Copilot, OpenCode, and [10+ more agents](https://github.com/vercel-labs/add-skill#available-agents).

### Manual Installation

```bash
git clone https://github.com/crafter-station/skills.git
cp -r skills/context-engineering/intent-layer ~/.claude/skills/
```

## Structure

```
skills/
├── context-engineering/     # Context optimization skills
│   └── intent-layer/        # Hierarchical AGENTS.md setup
├── workflows/               # Development workflow skills (coming)
├── generation/              # Code generation skills (coming)
└── marketplace.json         # Claude Code plugin discovery
```

## Contributing

1. Fork this repo
2. Create your skill following the [Agent Skills spec](https://agentskills.io/specification)
3. Test with Claude Code or your preferred agent
4. Submit a PR

## About Crafter Station

[Crafter Station](https://crafterstation.com) builds tools for the Peru tech ecosystem. We ship open source tools that make developers more productive.

## License

Apache 2.0 - See [LICENSE](./LICENSE)
