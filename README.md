# crafter-station/skills

context engineering skills for ai agents.

## install

```bash
npx skills add crafter-station/skills --skill intent-layer -g
```

works with claude code, cursor, copilot, and [10+ more agents](https://github.com/vercel-labs/add-skill#available-agents).

## skills

| skill | what it does |
|-------|--------------|
| [intent-layer](./context-engineering/intent-layer/) | AGENTS.md files so agents stop grepping in the dark |

### coming soon

| skill | what it does |
|-------|--------------|
| context-bundler | task-specific context selection |
| architecture-map | explicit system boundaries |
| invariants-capture | extract rules from git history |

## why

your agent burns 40k tokens on dead ends because it doesn't know where to look.

these skills give agents the context your senior devs have.

## contributing

1. fork
2. follow the [agent skills spec](https://agentskills.io/specification)
3. pr

## license

Apache 2.0
