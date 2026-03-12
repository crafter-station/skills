---
name: skillkit
version: 0.5.0
description: "Local-first production observability for AI agent skills. Use when user asks about skill usage, analytics, health, context budget, cost/burn rate, trigger conflicts, dead weight analysis, or wants to clean up unused skills. Complements skill-creator (authoring + eval) with monitoring + pruning."
---

# SkillKit

Production observability for AI agent skills. Monitors usage, detects conflicts, analyzes cost, and prunes what you don't use. Complements Anthropic's skill-creator which handles authoring and evaluation.

## Commands

SkillKit is a standalone CLI. Run with `npx @crafter/skillkit <command>` or install globally (`npm i -g @crafter/skillkit`).

### Usage & Budget

- `skillkit scan` - Discover skills + index session data (auto-runs on first use)
- `skillkit stats` - Usage analytics with sparklines (last 30 days)
- `skillkit stats --all --days 90` - Full list over 90 days
- `skillkit list` - Installed skills with size and context budget
- `skillkit health` - Unused skills + metadata budget check

### Cost Analysis

- `skillkit burn` - Daily burn rate, model breakdown, runway projection
- `skillkit burn --days 7 --plan 200` - Custom range and budget

### Quality & Conflicts

- `skillkit conflicts` - Detect trigger collisions between skills
- `skillkit coverage <skill-path>` - Find dead weight (unreferenced sections + files)

### Cleanup

- `skillkit prune` - List unused skills (add `--yes` to delete)

### Trace (Internal)

- `skillkit trace <prompt>` - Record skill execution trace (powers conflicts + coverage)

### Filters

- Any command with `--claude` or `--opencode` to filter by agent

## When to Use

- "which skills do I use the most?" → `skillkit stats`
- "are there unused skills?" → `skillkit health` then `skillkit prune`
- "how much am I spending?" → `skillkit burn`
- "do any skills conflict?" → `skillkit conflicts`
- "is this skill bloated?" → `skillkit coverage <path>`
- "show context budget" → `skillkit list`

## Decision Guide

1. First time? `skillkit stats` — auto-discovers and indexes everything
2. Full picture? `skillkit stats --all --days 90`
3. Cost check? `skillkit burn`
4. Conflicts? `skillkit conflicts`
5. Dead weight? `skillkit coverage ~/.claude/skills/my-skill/`
6. Cleanup? `skillkit health` then `skillkit prune --yes`

## How It Works

Discovers skills for 15+ agents (Claude Code, Cursor, Codex, Windsurf, Gemini CLI, Cline, Roo Code, Continue, OpenCode, GitHub Copilot, OpenHands, Amp, Goose, Kilo Code, Trae). Scans skill directories and project-local `.claude/skills/`. Indexes JSONL sessions extracting `Skill` tool_use blocks. Deduplicates skills.sh symlinks across agents. All data local in `~/.skillkit/analytics.db`.
