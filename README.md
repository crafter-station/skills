# crafter skills

Curated skills for AI agents.

**Browse at [skills.crafter.run](https://skills.crafter.run)** (coming soon)

## Install

```bash
npx skills add crafter-station/skills --skill intent-layer -g
```

Works with Claude Code, Cursor, Copilot, and [10+ more agents](https://github.com/vercel-labs/add-skill#available-agents).

## Skills

### Context Engineering

| Skill | What it does |
|-------|--------------|
| [intent-layer](./context-engineering/intent-layer/) | Set up AGENTS.md files so agents navigate your codebase like senior engineers |

## Contributing

1. Fork
2. Follow the [Agent Skills spec](https://agentskills.io/specification)
3. PR

## Website

The website is built with Next.js 16 and lives in the `website/` directory.

```bash
cd website
bun install
bun dev
```

See [website/README.md](./website/README.md) for more details.

## License

MIT
