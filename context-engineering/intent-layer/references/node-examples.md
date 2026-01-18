# Intent Node Examples

Real-world examples of effective Intent Nodes.

## Root Node (Monorepo)

```markdown
# Platform

Monorepo containing payment, billing, and user services.

## Architecture

```
platform/
├── services/          # Microservices (each has own DB)
├── packages/          # Shared libraries
├── platform-config/   # Runtime configuration
└── scripts/           # Build and deploy tooling
```

## Key Invariants

- Services communicate via message queue, never direct HTTP
- All config lives in `platform-config/`, never hardcoded
- Shared types in `packages/types/` - all services import from there

## Entry Points

- `services/api-gateway/` - All external traffic enters here
- `scripts/deploy.sh` - Production deployment

## Anti-patterns

- Never import between services directly
- Don't put business logic in packages/ (it's for utilities only)

## Related Context

- Payment service: `services/payment/AGENTS.md`
- Billing service: `services/billing/AGENTS.md`
- Config layer: `platform-config/AGENTS.md`
```

## Service-Level Node

```markdown
# Payment Service

Handles payment processing, refunds, and settlement.

## Purpose

Owns: Payment initiation, validation, processor communication, settlement
Does NOT own: Billing/invoicing (see billing service), user management

## Entry Points

- `src/api/` - REST endpoints (internal only, via API gateway)
- `src/workers/` - Background job processors
- `src/cli/` - Admin commands for manual operations

## Contracts

- All processor calls go through `src/clients/processor-client.ts`
- Settlement rules live in `../platform-config/rules/settlement.yml`
- Idempotency keys required for all payment mutations

## Patterns

Adding a new payment method:
1. Add type to `src/types/payment-method.ts`
2. Implement adapter in `src/adapters/`
3. Register in `src/adapters/index.ts`
4. Add validation rules in `src/validation/`

## Anti-patterns

- Never bypass `processor-client.ts` for external calls
- Don't store card numbers - use tokenization only
- Never mutate payments without idempotency key

## Pitfalls

- `src/legacy/` looks deprecated but handles edge cases for pre-2023 accounts
- Test mode uses real processor sandbox - charges still appear (voided)

## Related Context

- Processor adapters: `./adapters/AGENTS.md`
- Settlement logic: `../platform-config/AGENTS.md`
```

## Library/Package Node

```markdown
# Shared Types

TypeScript types shared across all services.

## Purpose

Single source of truth for cross-service types. All services import from here.

## Structure

```
types/
├── payment/     # Payment domain types
├── billing/     # Billing domain types
├── common/      # Shared primitives (Money, Timestamp, etc.)
└── events/      # Message queue event schemas
```

## Contracts

- Types here are the contract between services
- Breaking changes require coordinated deploys
- All event schemas must be backward compatible

## Patterns

Adding a new type:
1. Create in appropriate domain directory
2. Export from domain `index.ts`
3. Re-export from root `index.ts`
4. Run `bun run typecheck` across all services

## Anti-patterns

- Never put business logic here (types only)
- Don't import from services (would create circular deps)
- No runtime code - types must be stripped at compile time
```

## Configuration Node

```markdown
# Platform Config

Runtime configuration for all services. Loaded at startup.

## Purpose

Owns: Feature flags, settlement rules, rate limits, validation thresholds
Does NOT own: Secrets (use vault), environment config (use env vars)

## Structure

```
platform-config/
├── rules/           # Business rules (YAML)
├── features/        # Feature flags (JSON)
└── limits/          # Rate limits and thresholds
```

## Contracts

- All YAML schemas validated at deploy time via `scripts/validate-config.sh`
- Feature flags are boolean only - complex logic lives in services
- Changes require PR review from platform team

## Pitfalls

- `rules/settlement.yml` is the enforcement point for settlement policy
- Changes here affect ALL services on next restart
- Feature flags cached for 5 min in production

## Related Context

- Validation schemas: `./schemas/AGENTS.md`
- Settlement rules consumed by: `../services/payment/AGENTS.md`
```

## Compression Examples

### Before (too verbose, 800 tokens)

```markdown
# User Service

## Overview

The User Service is a microservice that is responsible for managing user accounts
in our platform. It handles user registration, authentication, profile management,
and user preferences. This service is built using TypeScript and Express.js, and
it uses PostgreSQL as its database through Prisma ORM.

## Technologies Used

- TypeScript 5.0
- Express.js 4.x
- PostgreSQL 15
- Prisma ORM
- Redis for caching
- Jest for testing
...
```

### After (compressed, 250 tokens)

```markdown
# User Service

Manages user accounts, auth, and preferences. Express + Prisma + PostgreSQL.

## Entry Points

- `src/routes/` - REST API
- `src/jobs/` - Background sync tasks

## Contracts

- Auth tokens from `packages/auth/`
- User events published to `events.users.*`

## Anti-patterns

- Never store passwords - use `packages/auth/hash.ts`
- Don't query users table directly from other services - use events

## Related Context

- Auth package: `../packages/auth/AGENTS.md`
```

## Key Principles Demonstrated

1. **Purpose before structure** - What it owns, what it doesn't
2. **Contracts are explicit** - Where things must go through
3. **Anti-patterns from experience** - Real mistakes to avoid
4. **Compression over explanation** - Assume Claude is smart
5. **Downlinks for depth** - Point to related context, don't duplicate
