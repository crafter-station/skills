---
name: surface-recon
version: 0.7.0
description: "Map what a target exposes and produce a recon report an implementer can build from. Works on web services and APIs, login-walled portals, desktop apps and compiled binaries, file formats, and hardware or accelerators whose real constraints are undocumented. Use when the user says 'recon this', 'reverse engineer this', 'map this API', 'figure out their endpoints', 'what does this device actually support', 'I want to build a CLI/client for X', or pastes a URL and asks what it exposes. Also use before building any integration against something whose contract you have not verified."
allowed-tools: Bash(agent-browser:*), Bash(npx agent-browser:*)
---

# surface-recon

Map what a target exposes, what it demands of you, and what will bite you. Produce a report someone else can build from without repeating your work.

This skill investigates. It does not design a command surface or write code: that is `cli-build`'s job. Stopping at a report is the point: recon tells you whether building is worth it.

## The one rule

**Every claim in the report is either observed or labeled as unverified.** A recon report that guesses without saying so is worse than no report, because the implementer trusts it and loses a day. Mark inference as inference.

Concretely: the endpoint table holds requests you observed. Everything else goes under "Needs verification", each with the step that would confirm it.

**Open `recon/friction.md` before Phase 0 and append to it as you go.** Every time a playbook is thin, a command fails for a reason its help text did not predict, or a gate does or does not hold, that is one line written at the moment it happens. It ships with the report and it is the only input that improves this skill. See [friction-log.md](references/friction-log.md).

## The tool

Observation happens through `agent-browser`, and that tool ships its own guides that stay version-matched with the binary. Load them rather than guessing commands from memory:

```bash
agent-browser skills get core           # the workflow: snapshot, refs, waits, sessions, mocking
agent-browser skills list               # what else is available
```

Two specialized ones carry most of the recon weight:

- **`derive-client`** turns a recorded session into a working client. For a website with an internal JSON API, it often does the whole of Terrain B better than hand-rolling: `agent-browser skills get derive-client`
- **`electron`** automates desktop apps over their debugging port, which beats unpacking them: `agent-browser skills get electron`

This skill deliberately does not restate what those cover. When a capability is documented there, [agent-browser-recon.md](references/agent-browser-recon.md) points at it instead of copying it, so the two cannot drift apart.

## When an instrument says the element is not there

**Screenshot first, and look at it with your own eyes.** If a page the user sees working reports "element not found", the capture comes before exhausting selectors, not after.

Three times in one project an indirect instrument said "does not exist" and the screenshot showed the element on screen: a login panel, a set of showtimes, a buy button. Each time the tooling was correctly built and pointed at the wrong thing. A login panel generates no traffic and contains no domain keywords, so it is invisible to a network tab and a DOM grep at the same time.

Two specifics worth knowing:

- **An open modal invalidates the entire accessibility tree.** A cookie banner returns as the whole snapshot, which reads as "the page has no content". Dismissing it is a precondition of any structural read, not a cleanup step.
- **Match on substrings, not equality.** A selector comparing against `19:20` finds nothing on a page rendering `19:20hs`.

The failure mode this prevents is not a missing tool. It is reaching for the instrument that represents you as someone who reads systems, over the one that answers the question.

## Phase 0: classify the terrain

Before touching a browser, decide which of these you are dealing with. The terrain determines the technique, and getting this wrong wastes the most time.

| Terrain | Tell | Go to |
|---|---|---|
| Official documented API | Public docs, OpenAPI spec, SDK on npm | [Terrain A](references/terrain-playbooks.md#official-documented-api) |
| Private API behind a SPA | App loads then fetches JSON/GraphQL | [Terrain B](references/terrain-playbooks.md#private-api-behind-a-spa) |
| Portal with a login you have | Session cookie, server-rendered forms | [Terrain C](references/terrain-playbooks.md#portal-with-credentials) |
| Portal with a login you do NOT have | Login wall, no account | [Terrain D](references/terrain-playbooks.md#portal-without-credentials), read this before starting |
| SPA on a BaaS | Supabase/Firebase client in the bundle | [Terrain E](references/terrain-playbooks.md#spa-on-a-baas) |
| No backend at all | Local file, export, data format | [Terrain F](references/terrain-playbooks.md#no-backend) |
| Desktop app or binary | Electron `.asar`, compiled binary | [Terrain G](references/terrain-playbooks.md#desktop-app-or-binary) |
| Hardware or an accelerator | A device or chip whose real contract is undocumented | [Terrain H](references/terrain-playbooks.md#hardware-or-an-accelerator) |

**Done when:** one terrain named, and for Terrain D, the credentials question answered before any other work.

Two terrains are traps worth naming up front:

**Terrain A is the one to hope for.** Always search for official docs, an OpenAPI spec, or an SDK *first*. When a public OpenAPI spec exists, recon is reading one file and you are done in minutes. Skipping this check and going straight to a browser is the single most common waste of time.

**Terrain D usually should not start.** Without credentials, a login-walled portal yields an inventory of what you *cannot* see, not a map. If the user wants that recon anyway, say plainly that the output will be a list of unknowns, and ask whether they can get an account first. See [gates.md](references/gates.md).

## Phase 1: check for an official surface

Run this before anything else, every time:

1. Search `{target} API documentation`, `{target} developer docs`, `{target} OpenAPI`, `{target} SDK`.
2. Try the conventional spec paths directly: `/openapi.json`, `/swagger.json`, `/.well-known/openapi.json`, `/api/schema`, `/llms.txt`.
3. Check npm/PyPI for an official SDK. An SDK's source is a documented API in disguise.

If you find a spec, read it and jump to Phase 4. Note the spec's own limitations: official docs are often incomplete rather than wrong, and the gap is what you need to reverse.

**Done when:** either a spec is in hand, or the searched queries are written down so the report can say "none found, searched X".

## Phase 2: observe real traffic

For a target that speaks over a network (Terrains B through E, and G), watch what it actually does.

**If it is a website with an internal JSON API, `derive-client` covers this phase end to end.** Record, identify endpoints among the noise, extract shapes and auth, verify. Run it:

```bash
agent-browser skills get derive-client
```

The commands for capture and interception live in `agent-browser skills get core`. What belongs here is only what recon adds on top:

- **Verify the domain you captured is where the functionality lives.** Institutional landing pages are not the app. Capturing `example.gob/agency` when the service runs on `service.agency.gob` produces a report full of nothing. This mistake happened three separate times in the corpus behind this skill.
- **Drive the actual action, not just the home page.** The endpoint you need appears when you click the thing, not on load.
- **Run each flow twice with different inputs.** Diffing the recorded URLs is what separates a parameter from a path.
- **Use a headed browser for first contact.** Anti-bot layers block plain `curl` and headless far more often than a real browser profile. Once you have a session, plain fetch usually works for the rest.
- **Keep the HAR, and treat it as a secret.** It is the receipt for every claim, and it holds live cookies and tokens. Out of version control, deleted when done.

**Then go past observation.** A HAR tells you what the client sent; it does not tell you what it depends on. Aborting an endpoint reveals which calls are load-bearing, and mocking a response reveals which fields are decoration. That is where recon stops guessing. See [agent-browser-recon.md](references/agent-browser-recon.md).

**Done when:** every flow the implementer needs has been driven at least twice, each captured request is attributable to an action you performed, and the HAR is saved. A capture you cannot map back to a click is noise.

Terrains A, F, and H skip this phase: a spec, a file, and a device each answer to a different tool.

## Phase 3: dig where traffic is not enough

When the network tab does not answer it:

- **Introspection disabled on GraphQL** (403 on `__schema`): the schema is still in the client bundle. Grep the chunks for operation names and field selections.
- **Request signing or custom headers**: the algorithm is in the bundle. Find the function that builds the header, then **verify by replaying a signed request outside the browser**. A signing algorithm you have not replayed is a hypothesis.
- **Desktop app**: connect to it rather than unpacking it. Every Electron app exposes a debugging port, so its private API becomes observable with the same workflow as a web page (`agent-browser skills get electron`). Keep `asar list` and `strings` for what never runs: dead paths, embedded source layout, endpoints the UI does not reach.
- **React SPA**: `react tree` and `react inspect` give you the data model the client believes in, which is often cleaner than the API response. Needs `--enable react-devtools` at launch. **Check that the tree is not empty before relying on it**: a server-rendered app with few client components returns almost nothing, and a production build has mangled component names. It is a fast path, not a guarantee.
- **Client-held state**: before deobfuscating a bundle, `eval` the framework globals. Hydration payloads and public config are frequently right there.
- **Hardware or an accelerator**: the acceptance boundary is the compiler or runtime, not a network call. Export a real workload and count what gets rejected or silently falls back, then measure per compute unit to confirm where it actually ran.
- **BaaS client**: the bundle names the tables, columns, and views directly.

Beware of large artifacts. A single minified file can be megabytes on one line; pipe to a file and grep the file rather than reading it into context.

**Done when:** every unexplained request from Phase 2 is either resolved or listed under "Needs verification". A signing algorithm counts as resolved only after a replay outside the browser succeeds.

## Phase 4: write the outputs

Write to the path the user asks for. Absent one, ask once, then default to `./recon/` in the current project.

**The report** is the deliverable every recon produces. The template, including the per-terrain variants for a file format and for hardware, is in [report-template.md](references/report-template.md).

**The IR** is a second artifact, written when the target has an HTTP surface and the verdict is "build it" or "build it narrowly". `surfacer` is a compiler that reads one `.surfacer.json` descriptor and emits six interfaces from it (a Rust shim, just-bash, help text, a TypeScript CLI, OpenAPI 3.1, and an MCP server) and does no recon of its own, so this skill is the producer of that file. Same findings, shaped for a machine instead of a reader.

The rule that governs it is the skill's own, made stricter: **only what you observed goes in the IR.** The report can carry inference because it has a column saying so; the IR has no such column, and everything in it is read as fact by six emitters and by `surfacer check`, which re-probes endpoints from the IR to detect drift. An inferred path there makes the drift check fire on something that never existed. Inference and "Needs verification" stay in the markdown.

The full field-by-field mapping, which terrains produce an IR and which cannot, and how the two runs from Phase 2 fill the `varies` and `observations` fields on parameters, are in [ir-target.md](references/ir-target.md).

**Done when:** every row of the endpoint table carries observed or inferred, every blocker names what got past it or that nothing did, and every "Needs verification" item names the step that would confirm it. Run [gates.md](references/gates.md) against the finished draft. If an IR was written, `surfacer lint recon/{siteName}.surfacer.json` passes and its endpoint count matches the observed rows of the report.

## Phase 5: verdict

Close with a recommendation, not just data. One of:

- **Build it.** The surface is stable and documented enough.
- **Build it, narrowly.** Only these endpoints are solid; the rest are a maintenance risk.
- **Do not build yet.** Blocked on credentials, or the surface is too unstable. Name what would unblock it.

State the maintenance risk plainly. An undocumented endpoint has no contract and no deprecation notice; it can break on any deploy. If the plan depends on coordinate-clicking a captcha or on a minified signing function, say that it will break and roughly when.

**Done when:** one of the three verdicts is stated, a reader could act on it without re-deriving your judgment, and `recon/friction.md` is handed over with the report. An empty friction log is a valid outcome; a missing one means it was never opened.

**Hand over `recon/friction.md` with the report.** Whatever slowed you down goes to whoever maintains the skill, and terrain friction in particular is what corrects a playbook.

## References

- [terrain-playbooks.md](references/terrain-playbooks.md): per-terrain technique, with what worked on real targets
- [anti-bot.md](references/anti-bot.md): what blocks recon and what gets through
- [agent-browser-recon.md](references/agent-browser-recon.md): interception, client state, React trees, desktop apps, session persistence
- [report-template.md](references/report-template.md): the report shape, with per-terrain variants
- [ir-target.md](references/ir-target.md): the surfacer IR contract, field by field, and which terrains can produce one
- [gates.md](references/gates.md): when to stop, and what to check before claiming a finding
- [friction-log.md](references/friction-log.md): capturing where the skill itself slowed you down

## Boundaries

**Stop at the report and the IR.** Implementation is `cli-build`'s work; recon's product is the verdict and, when there is a surface to compile, the descriptor of what was observed. The IR names commands because `lint_ir` demands a unique `commandPath` per operation, and that naming follows `cli-build`'s noun-verb convention rather than inventing a second one.

**Report the rate limit you measured.** "No limit headers observed, not measured" is a complete answer.

**Say what Terrain D yields before starting it.** Without credentials the output is a list of unknowns, and the user deserves to hear that first.

**Map a surface the user is entitled to use.** Recon works on services the user has access to and documentation they may read. A paywall, an authentication boundary you were not given, or personal data belonging to third parties marks the edge of the skill: the verdict there is "blocked", and that is a legitimate outcome.
