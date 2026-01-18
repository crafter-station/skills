---
name: intent-layer
description: >
  Set up hierarchical Intent Layer (AGENTS.md files) for codebases.
  Use when initializing a new project needing CLAUDE.md + AGENTS.md structure,
  adding context infrastructure to an existing repo, user asks to set up AGENTS.md,
  add intent layer, make agents understand the codebase, or scaffolding AI-friendly
  project documentation. Creates hierarchical context nodes that compress codebase
  knowledge for efficient agent navigation.
---

# Intent Layer

Set up hierarchical AGENTS.md infrastructure so agents navigate codebases like senior engineers.

## Workflow

```
1. DETECT existing context infrastructure
   - Check for CLAUDE.md at project root
   - Check for AGENTS.md at root and subdirectories
   - Read existing nodes to understand current coverage

2. DECIDE action based on state
   ┌─────────────────────────────────────────────────────────┐
   │ State                      │ Action                     │
   ├─────────────────────────────────────────────────────────┤
   │ Nothing exists             │ Full scaffold              │
   │ Only CLAUDE.md             │ Add AGENTS.md hierarchy    │
   │ Only AGENTS.md             │ Add CLAUDE.md instruction  │
   │ Both exist, incomplete     │ Propose additions          │
   │ Both exist, complete       │ Validate and suggest fixes │
   └─────────────────────────────────────────────────────────┘

3. EXECUTE changes
   - For new nodes: use Intent Node Template below
   - For updates: preserve existing content, add missing sections
   - Always ask user before creating/modifying files

4. VALIDATE hierarchy
   - No duplicated knowledge (use LCA principle)
   - Downlinks are explicit and correct
   - Progressive disclosure works
```

## Detection Commands

Before creating anything, run these checks:

```bash
# Check for existing context files
ls -la CLAUDE.md AGENTS.md 2>/dev/null

# Find all existing Intent Nodes
find . -name "AGENTS.md" -o -name "CLAUDE.md" 2>/dev/null | grep -v node_modules

# If nodes exist, read them first
cat AGENTS.md 2>/dev/null
```

## New Project Scaffold

For new projects, create both CLAUDE.md (project instructions) and AGENTS.md (hierarchical context):

```bash
project/
├── CLAUDE.md          # Project-level instructions (checked into git)
├── AGENTS.md          # Root Intent Node
└── src/
    └── AGENTS.md      # Child Intent Node (if needed)
```

CLAUDE.md content:
```markdown
# {Project Name}

## Quick Start
[How to run/build]

## Important
- Always read AGENTS.md files when entering a directory
- Follow downlinks to understand subsystems before modifying code
```

## Intent Node Template

Each AGENTS.md follows this structure:

```markdown
# {Area Name}

## Purpose
[1-2 sentences: what this area owns, what it explicitly doesn't do]

## Entry Points
- `main_api.ts` - Primary API surface
- `cli.ts` - CLI commands

## Contracts & Invariants
- All DB calls go through `./db/client.ts`
- Never import from `./internal/` outside this directory

## Patterns
To add a new endpoint:
1. Create handler in `./handlers/`
2. Register in `./routes.ts`
3. Add types to `./types.ts`

## Anti-patterns
- Never call external APIs directly; use `./clients/`
- Don't bypass validation layer

## Related Context
- Database layer: `./db/AGENTS.md`
- Shared utilities: `../shared/AGENTS.md`
```

## Placement Rules

Place Intent Nodes at semantic boundaries:

| Signal | Action |
|--------|--------|
| Responsibility shift | New AGENTS.md |
| Complex subsystem (>50k tokens) | New AGENTS.md |
| Hidden contracts/invariants | Document in nearest ancestor |
| Cross-cutting concern | Place at LCA (Least Common Ancestor) |

Do NOT create AGENTS.md for:
- Every directory (hierarchy handles coverage)
- Simple utility folders
- Test directories (unless complex patterns)

## Compression Targets

| Directory Size | Target Node Size |
|----------------|------------------|
| <20k tokens | Usually no node needed |
| 20-64k tokens | 2-3k token node |
| >64k tokens | Split into child nodes |

## Capture Interview Questions

When creating nodes for existing code, ask:
1. "What does this area own? What's explicitly out of scope?"
2. "What invariants must never be violated here?"
3. "What repeatedly confuses new engineers?"
4. "Where do bugs typically come from?"
5. "What patterns should always be followed?"

## Downlink Syntax

```markdown
## Related Context
- Payment validation: `./validators/AGENTS.md`
- Settlement rules: `../config/AGENTS.md`

## Architecture Decisions
- Why eventual consistency: `/docs/adrs/004.md`
```

## Existing Project Workflow

1. Run `scripts/analyze_structure.sh` to identify semantic boundaries
2. Start leaf-first: capture well-understood subsystems first
3. Use interview questions to extract tribal knowledge
4. Move up tree, summarizing child nodes (not raw code)
5. Place shared knowledge at LCA

## Validation Checklist

Before committing Intent Layer:

- [ ] Root AGENTS.md exists with architecture overview
- [ ] Each node < 4k tokens (compression, not weight)
- [ ] No duplicated facts (check LCA placement)
- [ ] Downlinks are explicit and correct
- [ ] Contracts/invariants documented (not just "what", but "why")
- [ ] Anti-patterns captured from real confusion

## Scripts

- `scripts/analyze_structure.sh` - Analyze codebase for semantic boundaries
- `scripts/estimate_tokens.py` - Estimate token count for directories

## References

- `references/node-examples.md` - Real-world Intent Node examples
- `references/capture-protocol.md` - Detailed SME interview protocol
