# crafter skills

Curated skills for AI agents.

## Install

```bash
# Install intent-layer
npx skills add crafter-station/skills --skill intent-layer -g

# Install skill-gen
npx skills add crafter-station/skills --skill skill-gen -g
```

Works with Claude Code, Cursor, Copilot, and [10+ more agents](https://github.com/vercel-labs/add-skill#available-agents).

## Skills

### Context Engineering

| Skill | What it does |
|-------|--------------|
| [intent-layer](./context-engineering/intent-layer/) | Set up AGENTS.md files so agents navigate your codebase like senior engineers. Built on [The Intent Layer](https://www.intent-systems.com/learn/intent-layer) by Tyler Brandt |

### Meta

| Skill | What it does |
|-------|--------------|
| [skill-gen](./meta/skill-gen/) | Create effective agent skills with guided workflows, validation, and packaging tools |

## Contributing

1. Fork
2. Follow the [Agent Skills spec](https://agentskills.io/specification)
3. PR

## License

MIT
