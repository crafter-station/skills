# crafter skills

Agent skills extracted from real work. Each one shipped something first.

## Install

```bash
npx skills add crafter-station/skills
```

That lists every skill and lets you pick. To install one directly:

```bash
npx skills add crafter-station/skills --skill supply-chain-audit -g
```

Works with Claude Code, Cursor, Copilot, and [10+ more agents](https://github.com/vercel-labs/add-skill#available-agents).

## Skills

Grouped by what the skill does for you. The Status column is explained under [Maturity](#maturity).

### Audit

Read-only. Produces a verdict, never modifies anything.

| Skill | Status | What it does |
|-------|--------|--------------|
| [supply-chain-audit](./skills/supply-chain-audit/) | stable | Scans a developer machine for npm/PyPI supply-chain compromise (Shai-Hulud 2.0, Mini Shai-Hulud / TeamPCP, Axios DPRK). Versioned IOC pack, three-phase scan, PASS/FAIL verdict, and 48h bake-period remediation |

### Build

Produces a new artifact from scratch.

| Skill | Status | What it does |
|-------|--------|--------------|
| [generate-brand-assets](./skills/generate-brand-assets/) | candidate | Generates OG images (1200x630) and favicon formats from a project's branding, with brand colors, gradients, PNG/WebP/ICO |
| [skill-gen](./skills/skill-gen/) | deprecated | Generated skills from documentation. See [Maturity](#maturity) before installing |

### Publish

Orchestrates a release without missing steps.

| Skill | Status | What it does |
|-------|--------|--------------|
| [obsidian-plugin-release](./skills/obsidian-plugin-release/) | candidate | Atomic release flow for Obsidian community plugins. Bumps the version across manifest.json, package.json, and versions.json, builds, lints, signs an annotated tag, and triggers a workflow that publishes with build-provenance attestation (SLSA in-toto). Passes the Obsidian Community automated review |

### Context

Structures a repository so agents navigate it well.

| Skill | Status | What it does |
|-------|--------|--------------|
| [intent-layer](./skills/intent-layer/) | candidate | Sets up hierarchical AGENTS.md files so agents navigate your codebase like senior engineers. Built on [The Intent Layer](https://www.intent-systems.com/learn/intent-layer) by Tyler Brandt |

## Maturity

Category and maturity are separate axes. The category says what a skill does; the maturity says how much evidence stands behind it. A `build` skill can be stable, and an `audit` skill can be experimental.

The source of truth is [maturity.json](./maturity.json), which carries the evidence for each status in one sentence.

| Status | Meaning |
|---|---|
| `stable` | Used on real work. Recommended |
| `candidate` | Works, with thin evidence so far |
| `experimental` | Coherent method and trigger boundary, no real-work use yet |
| `deprecated` | Kept for provenance. Not recommended |

How a skill moves:

- **Nothing enters as stable.** Extracted from work actually done starts at `candidate`. Written from documentation starts at `experimental`.
- **Promotion needs a named reason**, not a feeling. Which work it ran on, and what it caught.
- **`deprecated` is not deletion.** The folder stays and the install command keeps resolving. Anyone who already installed it deserves to find out it is unmaintained rather than hit a dead link.
- **Demotion is normal.** A skill that stopped earning its place says so.

## Skills that ship from their own repo

A skill that documents one tool belongs with that tool, so it cannot drift from the commands it describes. Those live in the tool's repository:

| Skill | Install |
|-------|---------|
| [skillkit](https://github.com/crafter-station/skill-kit/tree/main/packages/skill) | `npx skills add crafter-station/skill-kit` |
| [spoti-cli](https://github.com/crafter-station/spoti-cli/tree/main/skills/spoti-cli) | `npx skills add crafter-station/spoti-cli` |
| [sismo-cli](https://github.com/crafter-station/sismo-abierto/tree/main/skills/sismo-cli) | `npx skills add crafter-station/sismo-abierto` |

This repo keeps the skills that are not tied to a single codebase.

## Repository structure

```text
skills/<name>/SKILL.md            the installable catalog, flat
.claude-plugin/marketplace.json   plugin manifest
maturity.json                     category, status, and evidence per skill
```

The layout is flat on purpose. The skills CLI discovers `skills/<name>/SKILL.md`, and skills placed outside that container are invisible to the installer. Measured: a nested `skills/<category>/<name>/` layout found 1 of 3 skills in an isolated test, while the flat layout found 3 of 3.

So category is metadata, not a directory. It lives in `maturity.json` and drives the README grouping, which also means a skill can be recategorized without moving files or breaking a link.

## Contributing

1. Fork
2. Follow the [Agent Skills spec](https://agentskills.io/specification)
3. Add an entry to `maturity.json` with the evidence behind its status
4. PR

## License

MIT
