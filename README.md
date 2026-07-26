# crafter skills

Curated skills for AI agents.

## Install

```bash
# Install intent-layer
npx skills add crafter-station/skills --skill intent-layer -g

# Install skill-gen
npx skills add crafter-station/skills --skill skill-gen -g

# Install skillkit
npx skills add crafter-station/skills --skill skillkit -g

# Install supply-chain-audit
npx skills add crafter-station/skills --skill supply-chain-audit -g

# Install generate-brand-assets
npx skills add crafter-station/skills --skill generate-brand-assets -g

# Install obsidian-plugin-release
npx skills add crafter-station/skills --skill obsidian-plugin-release -g
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
| [skillkit](./meta/skillkit/) | Local-first analytics for AI agent skills. Tracks usage, measures context budget, prunes unused skills |

### Security

| Skill | What it does |
|-------|--------------|
| [supply-chain-audit](./supply-chain-audit/) | Read-only scanner for npm/PyPI supply-chain compromise (Shai-Hulud 2.0, Mini Shai-Hulud / TeamPCP, Axios DPRK). Versioned IOC pack, three-phase scan, PASS/FAIL verdict, and 48h bake-period remediation |

### Design

| Skill | What it does |
|-------|--------------|
| [generate-brand-assets](./generate-brand-assets/) | Generate OG images and favicon based on project branding. Creates social media preview images (1200×630px) and favicon formats, with support for brand colors, gradients, and multiple formats (PNG, WebP, ICO) |

### Developer Tools

| Skill | What it does |
|-------|--------------|
| [obsidian-plugin-release](./obsidian-plugin-release/) | Atomic release flow for Obsidian community plugins. Bumps version across manifest.json + package.json + versions.json, builds, lints, signs an annotated tag, and triggers a GitHub Actions workflow that publishes the release with build-provenance attestation (SLSA in-toto). Passes the new Obsidian Community automated review. |

## Skills that ship from their own repo

A skill that documents one tool belongs with that tool, so it cannot drift from the commands it describes. Those live in the tool's repository:

| Skill | Install |
|-------|---------|
| [spoti-cli](https://github.com/crafter-station/spoti-cli/tree/main/skills/spoti-cli) | `npx skills add crafter-station/spoti-cli` |
| [sismo-cli](https://github.com/crafter-station/sismo-abierto/tree/main/skills/sismo-cli) | `npx skills add crafter-station/sismo-abierto` |

This repo keeps the skills that are not tied to a single codebase.

## Contributing

1. Fork
2. Follow the [Agent Skills spec](https://agentskills.io/specification)
3. PR

## License

MIT
