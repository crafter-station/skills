---
name: skillkit
version: 0.6.0
description: "Local-first analytics for AI agent skills. Use when user asks about skill usage, analytics, health, context budget, cost/burn rate, trigger conflicts, dead weight analysis, or wants to clean up unused skills."
---

# SkillKit

Production observability for AI agent skills. Monitors usage, detects conflicts, analyzes cost, and prunes what you don't use.

## Commands

SkillKit is a standalone CLI. Run with `npx @crafter/skillkit <command>` or install globally (`npm i -g @crafter/skillkit`).

### Usage & Budget

- `skillkit scan` - Discover skills + index session data (auto-runs on first use)
- `skillkit stats` - Usage analytics with sparklines (last 30 days)
- `skillkit stats --all --days 90` - Full list over 90 days
- `skillkit list` - Installed skills with size and context budget
- `skillkit health` - Unused skills + metadata budget check

### Cost Analysis

- `skillkit context` - Context tax: tokens + cost of CLAUDE.md, skills, memory per API call
- `skillkit context --sonnet --turns 60` - Custom model pricing and session length (default: opus)
- `skillkit burn` - Daily burn rate, model breakdown, runway projection (40+ models priced)
- `skillkit burn --days 7` - Custom range
- `skillkit burn --set-plan` - Interactive plan selector (arrow keys)
- `skillkit burn --claude-plan 200 --cursor-plan 20` - Per-agent plan flags

### Quality & Conflicts

- `skillkit conflicts` - Detect trigger collisions between skills
- `skillkit coverage <skill-path>` - Find dead weight (unreferenced sections + files)

### Cleanup

- `skillkit prune` - List unused skills (add `--yes` to delete)

### Trace (Internal)

- `skillkit trace <prompt>` - Record skill execution trace (powers conflicts + coverage)

### Filters

- Any command with `--claude`, `--cursor`, `--codex`, `--gemini`, `--windsurf`, `--amp`, `--goose`, `--kiro`, `--roo`, or `--opencode` to filter by agent

## When to Use

- "which skills do I use the most?" -> `skillkit stats`
- "are there unused skills?" -> `skillkit health` then `skillkit prune`
- "what's my context tax?" -> `skillkit context`
- "how much am I spending?" -> `skillkit burn`
- "do any skills conflict?" -> `skillkit conflicts`
- "is this skill bloated?" -> `skillkit coverage <path>`
- "set my plan/budget" -> `skillkit burn --set-plan`

## Decision Guide

1. First time? `skillkit stats` -- auto-discovers and indexes everything
2. Full picture? `skillkit stats --all --days 90`
3. Context tax? `skillkit context`
4. Cost check? `skillkit burn`
5. Conflicts? `skillkit conflicts`
6. Dead weight? `skillkit coverage ~/.claude/skills/my-skill/`
7. Cleanup? `skillkit health` then `skillkit prune --yes`

## How It Works

Discovers skills across 12 agents: Claude Code, Cursor, Codex, Gemini CLI, Windsurf, Amp, Continue, Goose, Kiro, Roo Code, Antigravity, OpenCode. Session connectors parse JSONL/JSON traces for Claude, Cursor, Codex, Gemini, and OpenCode. Deduplicates skills by name and inode. All data local in `~/.skillkit/analytics.db`. Plan config stored in `~/.skillkit/config.json`.
