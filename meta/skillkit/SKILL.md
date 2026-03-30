---
name: skillkit
version: 0.10.4
description: "Local-first analytics for AI agent skills. Use when user asks about skill usage, analytics, health, context budget, cost/burn rate, trigger conflicts, dead weight analysis, or wants to clean up unused skills."
---

# SkillKit

Production observability for AI agent skills. Monitors usage, detects conflicts, analyzes cost, and prunes what you don't use.

## Commands

SkillKit is a standalone CLI. Run with `bunx @crafter/skillkit <command>` or install globally (`bun i -g @crafter/skillkit`).

### Usage & Budget

- `skillkit scan` - Discover skills + index session data (auto-runs on first use)
- `skillkit scan --include-commands` - Also track slash commands (not just skills)
- `skillkit stats` - Usage analytics with sparklines, streak count, weekly velocity (last 30 days)
- `skillkit stats --all --days 90` - Full list over 90 days
- `skillkit stats --json` - JSON output
- `skillkit list` - Installed skills with size and context budget
- `skillkit health` - Unused skills + metadata budget check
- `skillkit health --json` - JSON output

### Sessions & Activity

- `skillkit sessions` - Daily usage across all agents
- `skillkit graph` - 52-week contribution heatmap
- `skillkit graph --json` - JSON output
- `skillkit auto` - Auto-scan after Claude Code sessions (SessionEnd hook)

### Cost Analysis

- `skillkit context` - Context tax: tokens + cost of CLAUDE.md, skills, memory per API call
- `skillkit context --sonnet --turns 60` - Custom model pricing and session length (default: sonnet)
- `skillkit context --opus` / `--haiku` - Other model pricing
- `skillkit context --json` - JSON output
- `skillkit burn` - Subscription burn rate analysis (cost, models, daily)
- `skillkit burn --days 7` - Custom range
- `skillkit burn --plan 200` - Monthly plan cost in USD (default: 200)
- `skillkit burn --json` - JSON output

### Quality & Conflicts

- `skillkit conflicts` - Detect trigger collisions between skills
- `skillkit coverage <skill-path>` - Find dead weight (unreferenced sections + files)

### Cleanup

- `skillkit prune` - List unused skills
- `skillkit prune --yes` - Confirm deletion
- `skillkit prune --skill <name>` - Prune a single skill
- `skillkit prune --yes --json` - Confirm and output JSON

### Trace (Internal)

- `skillkit trace <prompt>` - Record skill execution trace (powers conflicts + coverage)
- `skillkit trace --list` - List recent traces
- `skillkit trace --list --json` - List recent traces as JSON
- `skillkit trace --show <id>` - Show trace details
- `skillkit trace --model <model>` - Model to use for trace

### Agent Filters

Any command accepts agent filters:
`--claude`, `--cursor`, `--codex`, `--gemini`, `--windsurf`, `--amp`, `--goose`, `--kiro`, `--roo`, `--opencode`

## When to Use

- "which skills do I use the most?" -> `skillkit stats`
- "are there unused skills?" -> `skillkit health` then `skillkit prune`
- "what's my context tax?" -> `skillkit context`
- "how much am I spending?" -> `skillkit burn`
- "do any skills conflict?" -> `skillkit conflicts`
- "is this skill bloated?" -> `skillkit coverage <path>`
- "show my activity heatmap" -> `skillkit graph`
- "daily usage breakdown" -> `skillkit sessions`

## Decision Guide

1. First time? `skillkit stats` -- auto-discovers and indexes everything
2. Full picture? `skillkit stats --all --days 90`
3. Activity? `skillkit sessions` then `skillkit graph`
4. Context tax? `skillkit context`
5. Cost check? `skillkit burn`
6. Conflicts? `skillkit conflicts`
7. Dead weight? `skillkit coverage ~/.claude/skills/my-skill/`
8. Cleanup? `skillkit health` then `skillkit prune --yes`

## How It Works

Discovers skills across 12 agents: Claude Code, Cursor, Codex, Gemini CLI, Windsurf, Amp, Continue, Goose, Kiro, Roo Code, Antigravity, OpenCode. Session connectors parse JSONL/JSON traces for Claude, Cursor, Codex, Gemini, and OpenCode. Deduplicates skills by name and inode. Self-healing DB deduplication on open. All data local in `~/.skillkit/analytics.db`. Plan config stored in `~/.skillkit/config.json`.
