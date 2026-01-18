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

### Claude Code

```bash
# Add marketplace
/plugin marketplace add https://github.com/crafter-station/skills

# Install a skill
/plugin install intent-layer@crafter-station-skills
```

### Manual Installation

```bash
# Clone and copy to your skills directory
git clone https://github.com/crafter-station/skills.git
cp -r skills/context-engineering/intent-layer ~/.claude/skills/
```

### Cursor / Copilot

Skills follow the open [Agent Skills standard](https://agentskills.io). Copy any skill's `SKILL.md` to your project or user skills directory.

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
