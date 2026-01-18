# Intent Layer Capture Protocol

Systematic process for extracting tribal knowledge into Intent Nodes.

## Capture Order

Work leaf-first, clarity-first:

```
1. Well-understood leaf areas (utilities, helpers)
2. Domain-specific modules (auth, payments)
3. Integration layers (APIs, clients)
4. Complex/tangled areas (legacy, core logic)
5. Root and intermediate nodes (summarize children)
```

## SME Interview Questions

### Purpose & Scope

- "In one sentence, what does this area own?"
- "What is explicitly NOT this area's responsibility?"
- "If someone wants to do X, where should they look instead?"

### Entry Points

- "Where does code execution typically start in this area?"
- "What are the main APIs/interfaces other code uses?"
- "What CLI commands or jobs run code here?"

### Contracts & Invariants

- "What must always be true here? What would break if violated?"
- "What are the implicit rules that aren't in the code?"
- "Are there ordering requirements? Dependencies that must exist?"

### Patterns

- "How do you add a new [typical task] here?"
- "What's the canonical way to do [common operation]?"
- "Show me a good example of [pattern] in this codebase."

### Anti-patterns

- "What mistakes do new engineers typically make here?"
- "What should never be done, even if the code allows it?"
- "What looks like it should work but doesn't?"

### Pitfalls & Landmines

- "What's the most surprising thing about this code?"
- "What looks deprecated but isn't?"
- "Where are the hidden dependencies or side effects?"

### Dependencies

- "What other areas does this depend on?"
- "What areas depend on this?"
- "Are there implicit contracts with other services?"

## Shared State Tracking

During capture, maintain running list of:

### Open Questions

```yaml
- question: "Is the legacy auth path still used?"
  context: "Found in user-service, unclear if production"
  blocked_until: "auth-service capture"
```

### Cross-References

```yaml
- fact: "Settlement rules are in platform-config/"
  applies_to: [payment-service, billing-service]
  lca_candidate: services/AGENTS.md
```

### Tasks

```yaml
- type: dead_code_candidate
  location: src/legacy/old_processor.ts
  evidence: "No imports found, last commit 2 years ago"
```

## Summarization Rules

When creating parent nodes:

1. **Summarize child Intent Nodes, not raw code**
   - Child nodes are already compressed
   - Parent adds structure and relationships

2. **Use LCA for shared facts**
   - Fact applies to multiple children? Move up
   - Only relevant to one child? Keep in child

3. **Add cross-cutting context**
   - How children relate to each other
   - Patterns that span multiple areas
   - Architectural decisions affecting subtree

## Node Quality Checklist

Before finalizing a node:

- [ ] < 4k tokens (compression achieved)
- [ ] Purpose statement in first 2 lines
- [ ] Contracts are explicit (not "handle carefully")
- [ ] Anti-patterns from real experience, not hypothetical
- [ ] Downlinks use relative paths
- [ ] No duplication with ancestor nodes

## Iteration Process

After initial capture:

1. Use node in real tasks
2. Note where agent gets confused
3. Add missing context
4. Remove unused/obvious information
5. Update compression ratio

## Example Capture Session

```
Interviewer: "What does this area own?"

SME: "Payment processing. We handle the lifecycle from
initiation to settlement. Billing is separate - they
handle invoicing. We just tell them 'this payment succeeded.'"

→ Node content:
## Purpose
Owns payment lifecycle: initiation → validation → processing → settlement.
Does NOT own: invoicing (see billing-service), user accounts.

Interviewer: "What invariants must never be violated?"

SME: "Every payment mutation needs an idempotency key. We had
an incident where a retry created duplicate charges. Now the
processor client enforces this at the type level."

→ Node content:
## Contracts
- Idempotency keys required for all mutations (enforced by ProcessorClient type)
```

## Time Estimates

| Codebase Size | Initial Capture | Per-PR Maintenance |
|---------------|-----------------|-------------------|
| <100k tokens | 2-3 hours | 5-10 min |
| 100k-500k tokens | 4-8 hours | 5-10 min |
| 500k-2M tokens | 1-2 days | 10-15 min |
| >2M tokens | 3-5 days | 15-20 min |

Maintenance is per-PR overhead, not weekly. Well-structured Intent Layers require updates only when behavior changes.
