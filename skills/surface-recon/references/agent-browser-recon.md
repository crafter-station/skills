# agent-browser for recon

This file does not teach agent-browser. The tool ships its own guides, version-matched with the binary, and they are more current than anything written here could stay.

**Load them first:**

```bash
agent-browser skills get core          # the workflow: snapshot, refs, waits, sessions, mocking
agent-browser skills get core --full   # adds the full command reference
agent-browser skills list              # what else is available
```

What follows is only the part that is specific to recon: which of the tool's capabilities answer which recon question, and the judgment calls the tool's own docs have no reason to make.

## Delegate the whole job when it fits

**`derive-client` is the closest skill to this work and often supersedes Terrain B entirely.**

```bash
agent-browser skills get derive-client
```

It covers record, identify, extract, generate, verify, including the `jq` queries for pulling endpoints out of a HAR, the auth-header comparison, and a symptom-to-cause table for verification failures.

Use it instead of hand-rolling when the target is a website with an internal JSON API and the goal is a client that calls it directly. Use `surface-recon` when the job is broader: deciding whether to build at all, a target that is not a website (Terrains F through H), a login-walled portal you cannot get into, or a report someone else will implement from.

The two compose. `surface-recon` decides the terrain and writes the verdict; `derive-client` does the heavy extraction inside Terrain B.

## Which capability answers which question

| Recon question | Capability | Where it is documented |
|---|---|---|
| What does it call? | `network har`, `network requests` | core, and `derive-client` for the jq queries |
| Which calls are load-bearing? | `network route --abort` | core: "Mock network requests" |
| Which response fields matter? | `network route --body` | same |
| What does the client already hold? | `eval --stdin` | core: "Extract data" |
| What is the data model? | `react tree`, `react inspect` | `--help react` |
| What does the desktop app talk to? | `connect <port>` | `skills get electron` |
| How do I get in without leaking a password? | `auth save`, `auth login` | `references/authentication.md` |
| How do I keep the session across a long recon? | `--session`, `--restore` | `references/session-management.md` |
| How do I export the session for a client? | `cookies get --json` | `derive-client` step 3 |
| Why did the tool itself break? | `doctor` | core: "Diagnosing install issues" |

Read the linked source rather than trusting this table's summary. The table is a router, not a reference.

## Interception is the technique with no manual equivalent

Worth calling out because it changes what a recon can conclude, and because a HAR-only recon quietly misses it.

Reading a request tells you what the client **sent**. It does not tell you what the client **depends on**. Interception answers that by changing the answer and watching what happens.

```bash
agent-browser network route "**/api/config*" --body '{"name":"MOCKED","files":[]}'
agent-browser eval "fetch('/api/config').then(r=>r.json()).then(j=>j.name)"
# "MOCKED"

agent-browser network unroute
agent-browser network route "**/api/config*" --abort
agent-browser eval "fetch('/api/config').then(()=>'OK').catch(e=>'BLOCKED: '+e.message)"
# "BLOCKED: Failed to fetch"
```

Both verified. What it buys a report:

- **Which endpoints are load-bearing.** Abort one at a time; the UI that breaks maps the dependency graph.
- **Which response fields are decoration.** Strip a field from the mock. If nothing changes, the client you build does not need to populate it.
- **What the error contract is.** Abort and read how the app reports failure. That is what you have to implement, and it is almost never documented.

### The discipline interception requires

Mocking makes the page lie on purpose. That is the point and also the hazard.

- **One route at a time.** Two active mocks and you cannot attribute what broke.
- **`unroute` before observing anything else.** Otherwise a later finding runs against your own fiction.
- **Label mock-derived findings in the report.** An aborted-endpoint conclusion is evidence about the client, not about the server.
- **Never leave a route active across a login.** A session obtained while intercepting auth calls has validity you cannot vouch for.

## Judgment calls the tool docs do not make

**Prefer connecting to a desktop app over unpacking it.** Every Electron app exposes a debugging port, so its private API is observable with the web workflow. Static unpacking (`asar`, `strings`) is the complement for what never runs: dead paths, endpoints the UI does not reach, embedded source layout. See Terrain G.

**Ask the page before deobfuscating the bundle.** `eval` on framework globals often returns the hydration payload, route manifest, and public config in seconds. Reserve chunk grepping for what the running page does not expose.

**`react tree` needs `--enable react-devtools` at launch.** Without it: `React DevTools hook not installed`. Verified. A server-rendered app also yields a nearly empty tree, and a production build has mangled component names, so treat it as a fast path rather than a guarantee.

**An empty tree is not evidence of an empty page.** Measured on one target: `react tree` returned nothing while the page rendered a full grid. Treat a null result from any structural instrument as "this instrument cannot see it", never as "it is not there". The cheapest way to tell them apart is a screenshot.

**A HAR holds live credentials.** Cookies, tokens, POST bodies. It is evidence you want to keep for re-verification and a secret you must keep out of version control. `derive-client` says the same thing; it is repeated here because a recon report that cites a HAR is exactly where someone commits one.

## Parallel recon

Each `--session <name>` is an isolated browser with its own cookies, tabs, and refs, which makes several independent recons safe to run at once. The mechanics are in core under "Run multiple browsers in parallel" and in `references/session-management.md`.

Two things that matter specifically for recon:

**Derive session names from the worktree** so parallel agents cannot collide:

```bash
SESSION="$(agent-browser session id --scope worktree --prefix recon)"
agent-browser --session "$SESSION" --restore open <url>
```

**Never share a session between an intercepted run and a clean one.** Routes are per-session, so a mock left active in a shared session contaminates the other recon silently. One session per hypothesis is the safe default.

## When the tool is not the answer

- **Terrain A**: an OpenAPI spec answers everything. Do not open a browser.
- **Terrain F**: the target is a file. Read samples.
- **Terrain H**: the target is a device. The acceptance boundary is a compiler or runtime, not a network call.

Reaching for a browser on these three is the most common way to spend an afternoon on a solved problem.
