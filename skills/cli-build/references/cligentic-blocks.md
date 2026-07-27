# cligentic blocks

A registry of CLI infrastructure primitives published as plain TypeScript files. Copy one into your project and you own it outright: no runtime dependency, no framework, no lock-in. Edit freely.

Registry root: `https://cligentic.railly.dev/r/`. Each block is served two ways: `<block>.ts` is the raw source, `<block>.json` is the registry entry with metadata.

**Default to using these.** Every CLI needs the same primitives, and hand-rolling them is where the time goes and where the bugs live.

## Installing a block

One curl, no tooling:

```bash
curl -o src/lib/atomic-write.ts https://cligentic.railly.dev/r/atomic-write.ts
```

That is the whole mechanism. No installer, no project config, no assumptions about your runtime or package manager.

Put the file wherever your project keeps its library code. The registry's own `agent/`, `foundation/`, `platform/`, `safety/` grouping is its layout, not a requirement.

## Dependencies

Two kinds, and both matter.

### Block dependencies, and yes they are recursive

Twelve of the twenty-two blocks are self-contained. The other ten declare `registryDependencies`, **and those dependencies have dependencies**. Resolving one level is not enough.

The graph, in full:

```
trust-ladder  -> json-mode, error-map
doctor        -> json-mode
next-steps    -> json-mode
json-mode     -> detect
banner        -> detect
copy-clipboard-> detect
notify-os     -> detect
open-url      -> detect
config        -> atomic-write
session       -> atomic-write
```

Maximum depth is 2, and there are no cycles. The deepest closures:

| Block | Transitive closure | Files |
|---|---|---|
| `trust-ladder` | trust-ladder, json-mode, error-map, detect | 4 |
| `doctor` | doctor, json-mode, detect | 3 |
| `next-steps` | next-steps, json-mode, detect | 3 |

**`trust-ladder` is the trap.** Its JSON names `json-mode` and `error-map`. Stop there and you are missing `detect`, which `json-mode` imports, and the build fails on a missing module. You need four files, not three.

Resolve the closure recursively:

```bash
fetch_closure() {
  local block="$1" root="${2:-src}"
  local meta; meta=$(curl -s "https://cligentic.railly.dev/r/$block.json")
  # The registry path carries the block's category, which the imports assume.
  local rel; rel=$(echo "$meta" | jq -r '.files[0].path' | sed 's|^registry/||')
  [ -f "$root/$rel" ] && return 0
  mkdir -p "$root/$(dirname "$rel")"
  curl -sS -o "$root/$rel" "https://cligentic.railly.dev/r/$block.ts" || return 1
  echo "fetched $rel"
  echo "$meta" \
    | jq -r '.registryDependencies[]? | split("/")[-1] | sub("\\.json$";"")' \
    | while read -r dep; do fetch_closure "$dep" "$root"; done
}

fetch_closure trust-ladder
# fetched agent/trust-ladder.ts
# fetched agent/json-mode.ts
# fetched platform/detect.ts
# fetched foundation/error-map.ts
```

The `[ -f ]` guard makes it idempotent and stops the diamond in the graph from fetching `detect` twice. Deriving the destination from `files[0].path` is what keeps the cross-folder imports working.

Without `jq`, follow the relative imports by hand. Everything that is not a `node:` built-in or an npm package is a block you still need:

```bash
grep "^import" src/lib/trust-ladder.ts
# import { createInterface } from "node:readline/promises";
# import { stdin as defaultStdin, stderr as defaultStderr } from "node:process";
# import { type EmitOptions, detectMode } from "./json-mode";
# import { AppError } from "../foundation/error-map";
```

Then repeat on `json-mode.ts`, which imports `detect`. That is the recursion, done manually.

### Keep the category folders

Blocks reference each other across the registry's category folders, so **a flat directory does not compile.** Fetching the `trust-ladder` closure into one folder produces two unresolved imports:

```
json-mode.ts(29,8):    TS2307: Cannot find module '../platform/detect'
trust-ladder.ts(8,26): TS2307: Cannot find module '../foundation/error-map'
```

Mirror the registry's grouping and the same four files typecheck clean:

```
src/
  agent/       trust-ladder.ts, json-mode.ts
  foundation/  error-map.ts
  platform/    detect.ts
```

So either place each block under its category, or flatten and rewrite the `../` imports to `./`. Pick one before fetching, since the layout is what the imports assume.

The category for each block is in the tables below, and also in its JSON:

```bash
curl -s https://cligentic.railly.dev/r/detect.json | jq -r '.files[0].path'
# registry/platform/detect.ts
```

### npm dependencies

Four blocks need a package installed. This is separate from the block graph and easy to miss:

| Block | Needs |
|---|---|
| `json-mode` | `picocolors` |
| `next-steps` | `picocolors` |
| `api-key-wizard` | `@clack/prompts` |
| `skill-installer-prompt` | `@clack/prompts` |

It propagates through the closure. Taking `trust-ladder` pulls in `json-mode`, so you need `picocolors` even though `trust-ladder` itself does not import it.

The JSON declares these under `dependencies`:

```bash
curl -s https://cligentic.railly.dev/r/json-mode.json | jq -r '.dependencies[]?'
# picocolors
```

Every other block imports nothing but Node built-ins.

Read the file after fetching. It is 50 to 200 lines of TypeScript, and understanding it is the point of the copy-paste model.

## The blocks

### Agent

| Block | What it gives you |
|---|---|
| `trust-ladder` | T0 to T3 approval gate plus a preview renderer. The core safety primitive. |
| `killswitch` | File-based emergency stop. A sentinel file exists, all writes refuse. |
| `json-mode` | `--json` detection plus structured stdout/stderr emit helpers. |
| `next-steps` | Structured `nextSteps` hints on stderr. Tells an agent what to run next. |
| `doctor` | Pre-flight environment check: dependencies, auth, connectivity. |
| `api-key-wizard` | Interactive key setup with validation and storage. |
| `skill-installer-prompt` | Offers to install an agent skill for your CLI from within the CLI. |

### Foundation

| Block | What it gives you |
|---|---|
| `audit-log` | Append-only JSONL logger for every write. |
| `audit-lifecycle` | Session start/end wrappers around the audit log. |
| `atomic-write` | Temp file, fsync, rename. Windows-aware. No partial writes on crash. |
| `xdg-paths` | XDG base directories, with a home override for test isolation. |
| `config` | JSON config reader/writer on top of `xdg-paths`. |
| `session` | Session id generation and tracking. |
| `error-map` | `AppError` with a structured code, a human message, and an actionable hint. |
| `argv` | Minimal argv parser, no framework dependency. |
| `global-flags` | The standard set: `--json`, `--yes`, `--dry-run`, `--verbose`. |
| `telemetry` | Opt-in telemetry gated on a local consent file. |
| `banner` | Startup banner with version and mode. |

### Platform

| Block | What it gives you |
|---|---|
| `detect` | OS, shell, and package manager detection. |
| `open-url` | Cross-OS `open` / `xdg-open` / `start`. |
| `copy-clipboard` | Cross-OS clipboard write. |
| `notify-os` | Native OS notification. |

### Safety

| Block | What it gives you |
|---|---|
| `killswitch` | Its own registry category. Listed under Agent above. |

## The core one

`trust-ladder` is the block to understand first. `approveGate()` is the whole idea:

```ts
await approveGate(ctx, preview, { trust: "T2", yes: flags.yes });
await placeOrder(order);   // only reached if approved
```

T0 and T1 pass through silently. T2 prompts for confirmation. T3 requires `--yes` plus an explicit confirmation id. The critical behavior: **in JSON mode or with piped input, any T2-or-higher gate throws instead of prompting**, so an agent receives a structured error rather than hanging on a prompt nobody will answer.

That behavior is why it depends on `json-mode` and `error-map`. Fetch all three.

## When not to adopt a block

Taking all of them reflexively is as wrong as writing everything by hand. The decision is per block, with a stated reason.

A real retrofit of an already-built CLI onto this registry produced this split:

- **Seven blocks replaced wholesale.** The hand-rolled versions were strictly worse, mostly around config paths, atomic writes, and error shapes.
- **Two kept as hybrids.** The block's structure was right but needed local behavior grafted in.
- **Seven rejected, each with a reason.** The most important rejection: the CLI had already published an envelope contract to agents, a specific `{ok, data, meta}` output shape documented as the agent interface. The registry's emit helper outputs the value directly. Incompatible shapes, and **a published contract outranks a shared block.** Adopting it would have broken every agent already consuming that CLI.

That is the general rule. Reject a block when:

- You have already published a conflicting contract that consumers depend on.
- Your domain needs strictly more than the block provides, such as a trust ladder with more tiers, or gates keyed on transaction size rather than command identity.
- The block assumes an interaction model your CLI does not have.

Accept a block when you are about to write the same thing from memory. That is nearly always the case for `atomic-write`, `xdg-paths`, `audit-log`, and `error-map`.

## Writing down the decision

Record which blocks you took, which you rejected, and why. Put it in the CLI's repo, not only in your head.

The next person to touch the CLI, or you in six months, will otherwise assume a hand-rolled version is an oversight and "fix" it back into a conflict. A short accept/reject/hybrid table with reasons prevents a whole category of regression.

## Caveats

**These are patterns, not a dependency.** After copying, the code is yours and upstream fixes do not reach you automatically. That is the tradeoff the model chooses deliberately: full ownership over automatic updates. If a block later gains a fix you want, diff the registry copy against yours.

**Curl is the portable path.** The JSON entries also follow a component-registry schema that some UI tooling consumes, which is fine if you already use that tooling and irrelevant otherwise: it expects a web project's configuration file that means nothing in a CLI. The raw endpoint works regardless of runtime, package manager, or language tooling.

**If you are not in a TypeScript project**, read the block source and reimplement the pattern. The patterns are the point; the files are a shortcut.
