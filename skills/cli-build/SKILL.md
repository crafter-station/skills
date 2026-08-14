---
name: cli-build
version: 0.12.0
description: "Design and build a CLI that an AI agent can operate safely and a human can supervise. Use when the user wants to build a CLI, wrap an API in a command-line tool, build a CRUD or local-first tool over a database or filesystem the user already owns, add --json or --dry-run to an existing CLI, design a trust ladder or approval gate for risky commands, wrap an async API so agents do not write their own poll loop, or decide how to distribute a CLI (npm, native binary, source). Runs on its own when the contract is yours to define; follows a surface-recon report when the target is someone else's service."
---

# cli-build

Build a CLI whose primary user is an agent and whose supervisor is a human. That inverts the usual defaults: machine-readable output is not a flag you add later, prompts are a failure mode in non-interactive contexts, and every write leaves a receipt.

## Phase 0: where does the contract come from

Every command you write reads or mutates something with a shape. This phase names that shape's owner, because it decides whether you go find the contract or write it.

**Discovered.** The CLI wraps a system you do not control: a third-party API, a login-walled portal, a device, an undocumented file format. The contract exists and is unverified, so guessing at it wastes more time than mapping it. **Run `surface-recon` first** and start from its report.

**Defined.** You own the model: CRUD over your own database, a scaffolder, a local transform, a wrapper around a library whose types you already have. There is nothing to reverse-engineer, so `surface-recon` has no input and skipping it costs nothing. **Write the contract instead**, in one pass before Phase 1: the entities, their fields and types, the operations allowed on each, and what makes a write irreversible. That artifact is what a recon report would have given you.

**Mixed.** A CLI over your own database that also calls a payment provider is discovered at the boundary and defined in the middle. Recon only the discovered part; do not let one external call turn the whole build into a recon job.

Say which one this is out loud before Phase 1, and write it into `friction.md`. An unstated classification defaults to discovered, which is how a defined build ends up blocked waiting for a report nobody can produce.

**Done when:** the origin is named, and either a recon report exists or the entities and operations are written down.

**Open `friction.md` next to the code now and append as you go.**

A block you rejected and why, a convention that turned out wrong for this domain, a reference that was thin. It folds into the case at the end, and it is what corrects this skill: seven claims inherited from an older version were false against the source, and they surfaced only because someone wrote down that they did not match.

## What agent-first actually means

**Every CLI, no exceptions:**

- **`--json`, and JSON automatically when stdout is not a TTY** even without the flag. Three CLIs converged on this independently; it is the most valuable default here.
- **No prompt ever blocks a non-interactive run.** Anything that would prompt fails with a structured error instead of hanging.
- **A `schema` command with a version field**, so agents introspect at runtime instead of parsing `--help`. Present in 3 of 14 corpus CLIs: the highest-value convention and the least adopted.
- **Exit codes that mean something.** Zero is success; user error and system failure are distinguishable.
- **Data on stdout, diagnostics on stderr, always.** Including the banner, which is why `banner` is a block and not a `console.log`.
- **A secret read from the terminal never echoes**, and returns `null` with no TTY rather than hanging. That is `prompt-secret`.

**When the domain has real consequences** (money, irreversible writes, third-party side effects, personal data):

- A trust ladder classifying commands by risk.
- `--dry-run` on every mutation, returning what *would* happen.
- An append-only audit log written **before** the network call, not after.
- A killswitch the human can trigger out of band.

**When the API is asynchronous:** `--wait` on every submitting command, backed by a job ledger that survives a killed poll. Handing the poll loop to the caller makes the agent write backoff logic it will get subtly wrong. See [compounding-surface.md](references/compounding-surface.md).

**Size the friction to the damage, and "none" is a real size.** Ask what one wrong call costs, then choose. A read-only CLI over a public dataset earns `--json` and a `schema` command and stops there: nobody loses anything by running the query twice. Intent tokens are for a wrong call that costs money. Adopting the full ladder for a tool that cannot hurt anyone is not caution, it is a tax the agent pays on every invocation, and it trains the human to approve without reading.

The question is damage, not distance. A `delete` against your own local database is irreversible even with no network, no money, and no third party in sight, so it earns `--dry-run` and a confirmation on the destructive verbs while the reads next to it earn nothing. Writes you can undo from a backup you actually have earn less. Grade the commands, not the project. See [trust-ladder-patterns.md](references/trust-ladder-patterns.md).

## Phase 1: decide the distribution target first

This comes first because it constrains the code you write, and retrofitting it is painful.

| Who installs this | Target | How |
|---|---|---|
| Only you, from source | Runtime shebang, no build | Fastest iteration, zero packaging |
| JS-ecosystem developers | Build to Node, publish to npm | `npx` works with no extra install |
| Anyone, no runtime | Compile to a native binary | No prerequisite at all |

**The rule that makes all three reachable: write against Node's API surface** (`fs`, `path`, `process`, `http`), not runtime-specific APIs. Then the target is a build-time decision instead of a rewrite.

**Done when:** the audience is named and the target follows from it, not from preference.

Why this matters more than it looks: nothing stops you from publishing a package whose shebang names a runtime the installer lacks. Three of the four published packages in the corpus behind this skill do exactly that. It works until someone without that runtime installs it and gets `env: <runtime>: No such file or directory`, a message that names no cause and no fix, so the package reads as broken rather than under-specified. See [build-and-runtime.md](references/build-and-runtime.md).

## Phase 2: shape the command surface

**Noun-verb, consistently**, and enforced in CI rather than agreed in a style guide. Agents carry a generalized model of what CLIs do; a tool that says `info` where everything else says `get` succeeds slowly, after the agent spends tokens on `--help`. Two corpus CLIs independently overloaded `--json` to mean input, which is what happens when nothing checks. See [compounding-surface.md](references/compounding-surface.md).

```
{cli} {noun} {verb} [args] [flags]

{cli} order preview --ticker AAPL --amount 100
{cli} order submit --intent-token <token>
```

Include a shorthand for the single most common operation. If ninety percent of use is one command, that command should be the shortest thing to type.

**Filter what deserves a command.** Not every UI affordance should be one. Keep actions that repeat, that benefit from being scriptable, that have clear input and output, and that compose with other tools. Drop the ones that are inherently visual or exploratory.

**Define the JSON contract per command before writing code.** Field names, types, nesting. This is the API agents depend on, and changing it later breaks them silently. Note that `--json` conventionally means output mode: if you need JSON *input*, give it a different flag name. Two corpus CLIs overloaded `--json` as an input flag and broke the convention agents expect. See [json-contract.md](references/json-contract.md).

**Done when:** every command has a noun-verb name and a written JSON output shape. A command whose output shape is undecided is not shaped yet.

**Add `nextSteps` to structured output.** Telling an agent what it can run next, in the response, prevents a class of flailing that `--help` does not.

**Shape the human view separately.** The machine mode returns everything because the agent filters; the human mode returns what a person asked for. Building one output for both serves neither. Everything about legibility, which metric direction a reader assumes, where a scale's thresholds go, when repetition is a heading, is in [human-output.md](references/human-output.md). This skill's other gates cannot catch an unreadable table: the first CLI built with it passed every one of them and printed 275 rows for someone who asked what was playing that evening.

**Polished human output is the default scope.** Unless the user explicitly asks for an MVP, minimal, headless, or machine-only CLI, include visual hierarchy, semantic color, readable tables, progress for work that takes time, and a TTY-only banner when the command has a human-facing surface. A small command count is not a reason to ship plain output. It is only a reason to keep the presentation compact.

## Phase 3: assemble from proven blocks

Every CLI needs the same primitives: flag parsing, config paths, atomic writes, audit logs, TTY detection, approval gates, error shapes. Writing them fresh each time is where the time goes and where the bugs live.

**Default to cligentic for TypeScript CLI infrastructure.** Its registry ships plain TypeScript that the project owns after installation, with transitive block and package dependencies resolved and no cligentic runtime dependency. Projects without `components.json` register the namespace in `package.json`, so component tooling is no longer a prerequisite.

The canonical adoption process lives in the [cligentic skill](https://github.com/Railly/cligentic/blob/main/skills/cligentic/SKILL.md). If `cligentic` is already available, follow it for discovery, per-block decisions, installation, wiring, and verification. If it is absent and implementation is in scope, offer to install it before changing files:

```bash
bunx --bun skills add Railly/cligentic --skill cligentic
```

Installing a skill changes the project or user environment, so wait for consent. If the user declines, the task is read-only, or skill installation is unavailable, read the canonical skill from GitHub and follow its adoption branch without installing it.

**Opt-in, per block, with a reason.** Each block earns its place by replacing something you would otherwise write from memory. For a human-facing TypeScript CLI, `detect`, `style`, and `banner` are the default presentation set unless the user reduced the scope explicitly. In a real retrofit, seven blocks were taken wholesale, two stayed as hybrids, and seven were rejected with reasons. The most important rejection was an output helper whose shape conflicted with an envelope already published to agents. A published contract outranks a shared block.

**Done when:** each block is adopted, hybridized, or rejected with the reason recorded in the repo. Silence about a rejection reads as an oversight to whoever touches it next.

If you are not in a TypeScript project, or the install path does not fit, read the block source and reimplement the pattern. The patterns are the point; the files are a shortcut.

## Phase 4: safety, sized to the damage

First, the exit: if no command in the surface can lose data, spend money, or touch a third party, this phase is one line in `friction.md` naming that fact, and you move on. A CLI that only reads, or only writes files it can rewrite, has nothing to gate. Record the finding so the next reader knows it was decided rather than skipped.

Otherwise read [trust-ladder-patterns.md](references/trust-ladder-patterns.md) and pick a shape. Three materially different ones exist in real code, and the right choice depends on the domain rather than on fashion.

Non-negotiables when the domain has consequences:

**Audit before, not after.** Write the pending record, make the call, write the final record with the same id. If the process dies mid-flight you have an auditable pending entry instead of silence. Day-bucketed JSONL, append-only, restrictive file permissions.

**Dry-run must exercise the real path.** A `--dry-run` that returns a hardcoded shape proves nothing. The strongest corpus implementation calls the provider's own preview endpoint and returns that.

**Consent gates are stricter than trust gates.** Legal acceptance should require a real TTY and have no `--yes` escape hatch at all. If an agent can accept terms on the human's behalf, the gate is decorative.

**Validate what came back before acting on it.** One corpus CLI refuses to submit unless the provider's preview screen literally contains the expected name, amount, and currency. That check catches both provider bugs and your own bad request construction.

**Done when:** every mutating command has a trust level and the ladder shape is chosen from the domain rather than copied, or `friction.md` records that no command in the surface carries consequence.

**Treat third-party response text as untrusted input.** Free-text from an external API can carry prompt injection aimed at the agent reading your output. Escape it before it reaches any place where it reads as instruction.

## Phase 5: wire every safety feature you name

A feature is **wired** when its call site exists. Until then it is a definition, and `--help` describing it is a claim the code does not back.

An audit-log module imported and never called. `--dry-run` parsed into a flags object no command body reads. `--help` advertising both. This shape is live in a package installable today, and it is strictly worse than having neither feature, because the operator, human or agent, believes there is a paper trail and a preview when there is nothing.

The check: grep for the call site. One hit, at the definition, means unwired.

**Done when:** every safety feature named in `--help` or the docs has a grep-confirmed call site.

Two more from the same corpus, both live in published packages:

- **Published with zero tests.** At minimum: the auth flow, the JSON output contract per command, and any signing or crypto code.
- **Dead code from a renamed product still reachable** from the entry point. Deprecated means removed, not merely unmentioned.

## Phase 6: verify, then write it down

**Link it globally first.** Before verifying anything, put the CLI on your PATH so you invoke it the way a user will:

```bash
bun link          # or npm link
which mycli && mycli --help
```

Running `bun run src/cli.ts` verifies a file. Running `mycli` verifies what ships: the bin entry, the shebang, the resolved dependencies, the banner. Three of those are invisible from a source-file invocation, and a broken `bin` path reaches a user's first install.

**Definition of done is observed behavior.** Run the command, read the output, and read it twice: once for correctness, once as someone who does not know the domain. What does the biggest number mean, what does the eye land on first, is there a column where every row says the same thing. See [human-output.md](references/human-output.md).

For a human-facing CLI, inspect the real TTY path and verify all of these before calling it done:

- the banner and diagnostics stay on stderr, while machine data stays on stdout;
- `--json`, piped output, and other machine modes contain no ANSI escapes;
- `NO_COLOR` disables styling without changing content;
- colored columns remain aligned using visible width rather than string length;
- long operations report real progress from completed work, not a timer animation.

**Verifying a new feature probes the old ones sharing its stream.** Confirming a fresh banner kept stdout clean turned up 810 bytes there, none of it the banner: a bare invoke had been writing help text to stdout with a nonzero exit since the previous round. Nobody had looked because bare invoke is not a case people test.

A green suite proves less than it appears to. What it misses, and how to close each gap, is in [testing.md](references/testing.md).

**Ship the agent's manual with the CLI.** A `skills/<name>/SKILL.md` in the CLI's own repo: commands, JSON envelope, the flags that matter, workflows worth composing. Without it every agent rediscovers the surface through `--help`, which is the cost this skill exists to remove. It lives with the code so it cannot drift, and it makes the CLI installable with `npx skills add <owner>/<repo>`.

**Then record the build** in [cases/](cases/): target, terrain, distribution choice, which blocks were adopted or rejected and why, what broke, what you would do differently. Fold `friction.md` in. Distill repeated findings into [conventions.md](cases/conventions.md), and read [portfolio-shape.md](cases/portfolio-shape.md) for the aggregate picture.

**Name your own code, not other people's.** A case about a CLI you wrote can be specific about what broke. A finding about someone else's package drops the subject and keeps the defect. The full boundary is in [cases/README.md](cases/README.md).

**Done when:** the CLI has been linked globally and run by its own name, its real output read, `skills/<name>/SKILL.md` exists with valid frontmatter, and a case file exists with `friction.md` folded in.

`npx skills add <owner>/<repo>` cannot be checked until the remote exists, and its failure for an unpublished repo is indistinguishable from a malformed SKILL.md unless you read the message. Valid frontmatter is a local check; installable is post-push.

This is the part everyone skips, and skipping it is why the same lessons get rediscovered. Before someone wrote the corpus down, four CLIs had independently reinvented the same audit-log design.

## References

- [cligentic skill](https://github.com/Railly/cligentic/blob/main/skills/cligentic/SKILL.md): live discovery, adoption, wiring, verification, and block authoring
- [trust-ladder-patterns.md](references/trust-ladder-patterns.md): three real shapes, chosen by domain
- [json-contract.md](references/json-contract.md): output mode, TTY detection, NDJSON as actually implemented
- [audit-log-patterns.md](references/audit-log-patterns.md): two-phase writes, and the dead-code trap
- [auth-patterns.md](references/auth-patterns.md): four observed architectures, rotation, secret handling
- [build-and-runtime.md](references/build-and-runtime.md): the distribution matrix in detail
- [testing.md](references/testing.md): what a green suite fails to prove
- [human-output.md](references/human-output.md): the reader, not the supervisor. Metric direction, calibrated scales, what the human default should be
- [cases/README.md](cases/README.md): how a case is written, and who may be named in one
- [compounding-surface.md](references/compounding-surface.md): async `--wait`, vocabulary enforced in CI, `--deliver` and `feedback`. Sourced from published work rather than the corpus, and labeled as such

## Boundaries

The phases above say what to do. These are the two that hold when a phase does not obviously apply:

**Store identifiers, take secrets from the environment.** A password belongs in memory for the session, or in a keychain. The persisted config holds the account id and the username.

**Claim what you implemented.** NDJSON, day-bucketed audit, and dry-run each earn a mention once the code does them, not before.
