# Terrain playbooks

These playbooks are routed by plane. Start with [terrain-model.md](terrain-model.md), then use every playbook matching the target profile.

Sections A through H are legacy archetypes retained because they encode techniques proven across public APIs, private GraphQL, government portals, LMS platforms, BaaS apps, file formats, desktop binaries, accelerators, and connected devices. They are a compatibility index, not the classification system.

The current terrain model separates access, exposed planes, acceptance proof, and maximum consequence. A single target can therefore require several playbooks without pretending that evidence from one plane proves another.

---

## A. Official documented API

**Tell:** public docs, an OpenAPI spec, or a maintained SDK.

**Technique:** read the spec. Stop there. Do not open a browser.

Try these paths directly before searching, they are free:

```
/openapi.json  /swagger.json  /.well-known/openapi.json
/api/schema    /api/docs      /llms.txt
```

An SDK's source counts as documentation. Reading `src/` of an official client tells you the endpoints, the auth header, and the error shape at once.

**What this looks like when it goes right:** a spec of a few thousand lines answers every question, confidence is high, and there is nothing adversarial to do. Two of the corpus targets needed zero browser work because a public OpenAPI JSON was served unauthenticated.

**The trap:** partial official coverage. Docs exist but the endpoint you need is not in them, or your account tier lacks access to the documented API. Then you are in Terrain B for the missing piece while Terrain A covers the rest. Say so in the report rather than pretending uniform confidence.

---

## B. Private API behind a SPA

**Tell:** the page loads, then fetches JSON or posts GraphQL.

**First: check whether `derive-client` should just do this.**

```bash
agent-browser skills get derive-client
```

That skill covers record, identify, extract, generate, and verify for exactly this terrain, including the `jq` queries that pull endpoints out of a HAR and a symptom-to-cause table for verification failures. If the goal is a client that calls the internal API directly, run it and come back here for the verdict.

Stay in this playbook when the question is broader: whether to build at all, or a report someone else implements from.

**Technique:** HAR capture while driving the real action, then the bundle for whatever the traffic does not explain. The commands are in `agent-browser skills get core` under "Mock network requests"; the recon-specific part is what to drive and what to keep.

- Exercise every flow the eventual client needs, **each one at least twice with different inputs**. Diffing the recorded URLs is what separates a parameter from a path.
- Log in *before* starting the HAR, so credentials do not land in the recording. Export the session separately with `cookies get --json`.
- Text response bodies are embedded by default, so the HAR alone is studiable offline after the browser closes. Cap is 2 MB per body.
- **Separate the API from the noise.** Telemetry (`/collect`, `/track`, `/beacon`), third-party analytics and error reporting, and static assets will outnumber the real endpoints. The API is usually first-party, JSON, and correlates with the action you just performed.
- **Record the headers, not only the URL and body.** Some endpoints 403 without a matching `user-agent`, `referer`, or `x-requested-with`, and that is invisible until a client reproduces the request without them. Test by omission before declaring a header optional.

**Before deobfuscating anything, ask the page what it holds.** `eval` the framework globals: hydration payloads, route manifests, and public config are frequently sitting in `window.__NEXT_DATA__`, `window.__NUXT__`, or `window.__APOLLO_STATE__`. Minutes of this can replace hours of chunk grepping.

**On a React app, read the components instead of the traffic.** `react tree` plus `react inspect` returns props and hook state, which is the data model the client believes in, post-normalization and often cleaner than the API response. Requires `--enable react-devtools` at launch.

When GraphQL introspection is disabled (403 on `__schema`), the schema is still shipped to the client. Grep the chunks for operation names and selection sets. The hardest case in the corpus required deobfuscating 119 Nuxt chunks to recover a full 90-operation schema plus the request-signing algorithm; that is the floor, not the first move.

**Then verify which of it matters.** A capture shows what the client sent, not what it depends on. Aborting an endpoint shows whether the app needs it; mocking a response with a field removed shows whether that field is load-bearing or decoration. This is the step a HAR-only recon skips, and it is the one that makes an endpoint table trustworthy. See [agent-browser-recon.md](agent-browser-recon.md).

**A value in the site's public config is probably required everywhere, not only where you first saw it.** One recon documented a sales-channel token for the endpoint where it appeared and found later that a second endpoint rejected requests without it. Measured one parameter at a time: two ids gave 500, adding a third still gave 500, adding the token gave 200. When a config blob exposes a token, test it against every call in the flow rather than the one that revealed it.

**Read a client someone else wrote for the same backend.** Two chains running the same ticketing engine share its quirks. One project found a comment in an unrelated CLI saying the seat grid's horizontal axis is mirrored, could not confirm it against an invented fixture, and wrote the question down. The first live capture confirmed it exactly: grid position 1 was seat 13. A one-line fix, and the reason it was a day-one fix instead of a silent UI bug is that reading neighboring code produced the question weeks before there was data to answer it.

**Read the error body before diffing headers.** A replay that fails often names what is missing: on the first real run of this skill, a 500 returned `"Country undefined not implemented"`, which identified the one required header outright. Diffing your request against the HAR also works and is slower. Read what the server told you first.

**Request signing:** if requests carry a signature header, the function that builds it is in the bundle. Find it, then **replay a signed request from outside the browser to prove you understood it.** In the corpus the signed message turned out to be `timestamp + query-with-spaces-stripped + platform_os + app_version`, a shape nobody would guess, and only a replay confirms it.

**Session values that rotate:** some servers return a fresh session key on every response and expect the next request to use it. Miss one rotation and everything after fails. Check whether any response header changes between two identical calls. Three separate targets in the corpus did this.

---

## C. Portal with credentials

**Tell:** server-rendered forms, session cookie, you have an account.

**Technique:** log in with a real headed browser, then map the internal XHR the pages call. Server-rendered portals often have a JSON layer underneath the HTML that is far nicer to consume than the pages.

Steps that repeatedly worked:

1. Log in headed. Use the credential vault rather than the command line, so the password never lands in shell history: `agent-browser auth save <name> --url <login> --username <u> --password-stdin`, then `auth login <name>`. Capture the cookie name and shape.
2. Look for a CSRF or session token in the DOM. Some frameworks put it in a global JS object or a meta tag, and it changes on every login: plan to re-extract it rather than cache it.
3. Watch the XHR the page fires. Those are your endpoints.
4. For pages with no XHR, parse the HTML. `cheerio` over a fetched page is stable enough when the markup is server-rendered and old.
5. Check what an unauthenticated deep link does. The redirect target is your "am I logged in" signal.
6. Persist the session with `--session` plus `--restore` so a recon spanning many commands does not re-login each time. On a portal with a captcha this is the difference between feasible and not.

**Gotchas from real portals:**

- **A 200 is not success.** One login endpoint returned HTTP 200 with a wrong password; only a field in the JSON body said whether it worked. Always parse the body before deciding.
- **Data you need may not be in the HTML at all.** One video platform exposed only the currently-loaded item's ID in the DOM; getting the rest required clicking each playlist entry headed and capturing the change. Static scraping could never have found them.
- **Names lie.** One endpoint named after a specific cloud provider served a completely different provider's blob storage, left over from a migration nobody renamed around. Do not infer the backend from the route name; read the response headers.
- **Encoding details are load-bearing.** One parameter needed double URL-encoding; single-encoding worked most of the time and failed silently the rest. Replicate exactly what the browser sent.

---

## D. Portal without credentials

**Read this before starting. The honest answer is usually "don't".**

**Tell:** login wall, and no account.

**What actually happens:** you produce an inventory of routes you cannot reach. In the corpus, six targets were reconned this way. Between 80 and 90 percent of their endpoint tables ended up marked as unverified, auth patterns were inferred from URL shapes rather than observed, and no request bodies were ever captured. Those reports could not be built from.

**If the user still wants it, do this and label what it is:**

1. Map the public surface: what pages exist, what the login flow looks like, which subdomains serve what.
2. Note the anti-bot layer on the way in, since it will matter later.
3. Write the report with `confidence: low` and put nearly everything under "Needs verification".
4. State the one thing that unblocks it: an account.

**The alternative worth proposing:** many login-walled services have a public consultation form or an open-data export that answers the same question without an account. Look for that before accepting a low-confidence report.

---

## E. SPA on a BaaS

**Tell:** a Supabase, Firebase, or similar client initialized in the bundle.

**Technique:** read the production bundle. The client library call sites name the tables, the columns, the filters, and often the entire auth flow. You may not need to create an account or capture any traffic.

Faster first move: `eval` the globals. A BaaS client usually leaves its project URL and public key on `window`, which gives you the base URL and the anon key without reading a single chunk.

**The subtle part:** distinguish tables from views. One target exposed a view that merged explicit user overrides with inferred state; writing to it directly would have broken the model, because writes belong on the underlying table and the view recomputes. Read the call sites carefully enough to tell which is which.

Row-level security means the shape you read from the bundle is not the same as what your key can actually access. The bundle gives you the schema; only a real call gives you the permissions.

---

## F. No backend

**Tell:** the target is a file format, a local export, or a data dump. No server to interrogate.

**Technique:** get real sample files and read them. Three corpus targets landed here; a JSONL conversation log, a health-app XML export, and an embedded tile manifest; and in all three the recon was "scan actual samples", not "capture traffic".

What to document instead of endpoints:

- The schema, including fields that appear only sometimes.
- Version drift between samples produced at different times.
- Non-obvious encodings. One export used `2026-04-10 08:12:00 -0500`, a space instead of `T`, no colon in the offset. Naive ISO parsers fail on it.
- Size. Files that must be streamed rather than loaded change the design.

Watch out for large single-line files. Grepping a multi-megabyte artifact through stdout crashed a harness in one corpus case; pipe to a file first, then grep the file.

---

## G. Desktop app or binary

**Tell:** the target is an installed application, not a website.

**Technique, if it is Electron: connect to it, do not unpack it.**

Every Electron app is Chromium and exposes a debugging port, which makes its private API observable with the same workflow as a web page:

```bash
open -a "Slack" --args --remote-debugging-port=9222   # macOS
agent-browser connect 9222
agent-browser snapshot -i
agent-browser network requests --type xhr,fetch --json
```

The network tab now shows the real backend the app talks to, without touching its bundle. Launch flags per OS and per app: `agent-browser skills get electron`.

**Static unpacking is the complement, not the starting point.**

```bash
asar list app.asar                 # inventory
asar extract app.asar ./out        # then grep the JS
strings <binary> | grep -i <term>  # compiled: embedded strings
```

It earns its place for what never runs: dead code paths, endpoints the UI does not reach, and embedded source paths that reveal internal module layout for free. For a compiled binary with no Chromium inside, this is the only route.

If the app exposes a local server or an MCP surface, enumerating its tool list beats reading any code.

Extraction output can be enormous. Extract to disk and search on disk. Do not pull dumps into context.

---

## H. Hardware or an accelerator

**Tell:** the target is a device, a chip, or a fixed-function unit, and its real contract is not in the vendor documentation.

The vendor's docs describe an idealized interface. What you need is the constraint set that decides whether your work is accepted at all, and that is usually undocumented.

First classify the subtype:

- **Accelerator:** the hidden contract is workload acceptance, fallback, layout, and performance.
- **Connected device:** the hidden contract is split across discovery, control, data, storage, update, and accessory planes. Read [hardware-protocol-recon.md](hardware-protocol-recon.md) before interacting.

**Accelerator technique, in order:**

1. **Read the literature before touching the device.** Somebody has probably already characterized it. A published constraint catalog saves days of bisection, and citing it is faster and more accurate than rediscovering it.
2. **Enumerate what is actually present.** The OS knows more than the docs: device trees and registries, connected-device listings, driver and firmware versions.
3. **Find the acceptance boundary by submitting work.** For an accelerator this is the compiler or the runtime: export a real workload and count how many operations get rejected or silently fall back to another unit. A zero-rejection export is the receipt that your understanding of the constraints is complete.
4. **Measure per unit, not in aggregate.** A device that reports one number hides where the work went. Power and throughput broken out by compute unit is what tells you whether the accelerator ran your workload or quietly handed it to the CPU.
5. **Replay against a baseline on the same silicon.** "Faster" means nothing without a same-size comparison measured on the same machine under the same load.

**Connected-device technique, in order:**

1. Enumerate each physical and logical plane without writing to it.
2. Record the complete context matrix: model, firmware, host, transport, topology, mode, power, lock, activation, storage, and pairing state.
3. Advance through the mutation ladder one rung at a time. Get explicit approval before persistent pairing, state transitions, data writes, or firmware operations.
4. Enable capture and receive paths before authentication. Replay only source-backed frames and distinguish acknowledgement from verified state change.
5. If the transition can remove the controller, stage a one-shot local runner with timeout, cleanup, recovery, and receipts before changing state.
6. Correlate surprising values with another plane. Zero, null, silence, rejection, accepted calls, and verified state are different states.
7. Preserve a compact sanitized receipt and the exact failure that changed the probe.

**What this looks like when it works:** one accelerator target yielded a constraint catalog verified by zero export rejections and per-unit power measurement. One connected camera yielded separate USB storage, BLE discovery, persistent application pairing, and telemetry contracts. A generic version query was rejected on BLE and a storage status reported zero while USB exposed the real capacity. Those contradictions were findings, not noise: command support was transport-specific and status semantics were mode-dependent.

**Gotchas specific to this terrain:**

- **Silent fallback is the failure mode.** Unlike a web API, a device rarely errors. It accepts the work and runs it somewhere slower. Always verify *where* it executed, never assume from the absence of an error.
- **Separate what you measured from what you read.** A published catalog is a citation, not your finding. Keep them distinct in the report; conflating them is how a paper's claim becomes your unverified assumption.
- **The contract is versioned by context.** Record silicon or hardware revision, firmware, host, OS, toolchain, transport, topology, and device mode.
- **Aggregate metrics lie.** Total power and wall-clock time cannot tell you which unit did the work.
- **Pairing is persistent state.** Read-only intent does not make its setup read-only. Use a stable private identity and obtain approval at that boundary.
- **A response is not support.** Parse the status and validate the state. Scope every result to the target, transport, and mode that produced it.
- **Hashes are not redaction for low-entropy payloads.** Use opaque per-session variants or a non-retained keyed digest.
- **The control channel can be part of the experiment.** Tailscale over the Wi-Fi interface being switched will disappear with that interface. Run the transition locally and restore it without the controller.
- **Host permissions are launch-surface specific.** SSH, Terminal, and an app can receive different Bluetooth, location, and accessibility decisions on the same Mac.
- **Success return codes are not state receipts.** Verify target identity, address, peer reachability, and service reachability separately.
- **Documentation can lag the executed path.** Resolve contradictions against the current code path and physical capture before sending a state-changing fallback command.

Terrain H is now a legacy route into the device, firmware, or runtime planes. It ends in a context-scoped contract. Accelerators and non-HTTP device planes use constraint or command matrices. An independently observed HTTP plane can also produce the endpoint table and IR described in [ir-target.md](ir-target.md).

---

## Command plane: CLI, SDK, MCP, or daemon

**Tell:** the stable interaction surface is commands, functions, tools, schemas, stdin/stdout, or local IPC.

**Technique:** enumerate before invoking. Capture help, version, schemas, exit codes, stdout, stderr, state before, and state after. For an MCP server, list tools, resources, prompts, and their input schemas before calling anything. For an SDK, use type definitions and official examples as cited evidence, then execute a minimal fixture.

**Acceptance proof:** contract conformance. A successful command is not enough. The invocation must match the advertised schema, return the documented output class, use the expected exit state, and produce the intended poststate.

**Gotchas:**

- Human-readable output can hide a nonzero exit code.
- A daemon may acknowledge a command before the work finishes.
- MCP tool discovery proves availability, not semantics.
- Local sockets and lock files can retain state between supposedly isolated runs.

---

## Interactive plane: desktop or mobile UI

**Tell:** the user-visible state and interaction sequence are part of the contract.

**Technique:** inventory screens, controls, keyboard paths, accessibility roles, local state, and visible transitions. Use a disposable project or account. If the app is Electron, Terrain G still supplies the strongest instrumentation. Otherwise combine accessibility inspection, screen observation, process inventory, and artifact diffs.

**Acceptance proof:** state transition. Record the precondition, action, visible transition, persisted result, and recovery path. Coordinate clicks without a stable semantic anchor are weak evidence.

**Gotchas:**

- A visible toast can report success before persistence finishes.
- Restarting the app may reveal that a change never saved.
- A UI action can mutate both a local project and a cloud account.
- Authentication belongs to the access profile, not to the UI technology.

---

## Artifact plane: files, projects, exports, and media packages

**Tell:** durable files are the integration boundary, even when another plane creates them.

**Technique:** generate two minimal samples with one controlled difference, normalize volatile fields, diff structure, mutate only a disposable copy, then reopen it in the producer. Terrain F covers raw schema discovery; this playbook adds producer-consumer round trips.

**Acceptance proof:** round trip. The producer must reopen the artifact, preserve unrelated structure, and expose the intended change. Parsing alone proves only that your parser accepted the file.

**Gotchas:**

- ZIP-based projects often contain indexes, checksums, or derived previews.
- Timestamps and random identifiers create noisy diffs.
- Sidecar files may be more load-bearing than the visible media.
- Export compatibility does not imply project compatibility.

---

## Device plane: USB, BLE, serial, or HID

**Tell:** the boundary is a physical transport carrying descriptors, characteristics, frames, reports, or vendor commands.

**Technique:** establish target identity first. Enumerate descriptors and read-only state, capture one known-good interaction from the official client, replay the smallest reversible operation, and verify the device poststate independently. Keep transport discovery separate from protocol interpretation. Use [hardware-protocol-recon.md](hardware-protocol-recon.md) for the full context matrix and mutation ladder.

**Acceptance proof:** receipt plus poststate. A write completing only proves that bytes left the host. Require a protocol receipt when available and an independently observed state change.

**Gotchas:**

- BLE may bootstrap Wi-Fi without carrying the main control protocol.
- USB mass storage and USB vendor interfaces are different planes on the same cable.
- Serial framing can be correct while checksums or sequence numbers are wrong.
- HID output reports can be accepted silently and ignored.
- Device identity can change after reboot, mode switch, or re-enumeration.

---

## Firmware plane: update packages, partitions, and boot behavior

**Tell:** the durable target is software executed by a device before or below the normal application layer.

**Technique:** stay offline first. Hash the package, identify container structure, manifests, signatures, partitions, compression, and version checks. Compare at least two official versions when available. Map the boot and recovery path before any write.

**Acceptance proof:** boot and recovery. Static unpacking proves package understanding, not that a modified image is safe or accepted. Flashing requires explicit authorization, a backup, a verified recovery route, and a target the operator can afford to lose.

**Gotchas:**

- A valid outer package can contain signed inner images.
- Anti-rollback counters can make a reversible-looking test permanent.
- Calibration, pairing, and serial data may live beside firmware.
- A successful flash receipt does not prove a successful boot.

---

## Runtime plane: compiler, accelerator, or execution substrate

**Tell:** the boundary decides whether work is accepted, transformed, rejected, or silently executed elsewhere.

**Technique:** enumerate versions and capabilities, submit controlled workloads, inspect compilation or placement receipts, measure per execution unit, and compare against a baseline on the same machine.

**Acceptance proof:** execution placement. A successful result is insufficient when silent fallback exists. Prove where the work executed.

**Gotchas:** retain all accelerator constraints from legacy Terrain H, especially silicon, OS, and toolchain specificity.

---

## Composite systems

Use a separate evidence row for every plane boundary. Correlate them by timestamp, stable identifier, or controlled state transition.

An owned camera can expose BLE for discovery, Wi-Fi for control and media, USB mass storage for files, a vendor USB interface for commands, and firmware update packages. A screen-recording app can expose UI state, project artifacts, command hooks, and media exports. Neither target has one terrain.

The composite acceptance rule is strict: every claimed bridge needs its own proof. BLE discovery does not prove camera control. A media file appearing over USB does not prove the vendor command protocol. A UI toggle changing does not prove the project persisted until the artifact survives reopen.

---

## Cross-profile: what always goes in the report

Regardless of profile:

- **Auth flow, observed.** Header names verbatim. Token lifetime. Whether anything rotates.
- **Rate limits, as measured.** If no limit headers appeared and you did not probe, write "no limit headers observed, not measured". Do not invent a number. Six corpus reports all adopted the same polite default without measuring, which reads like evidence and is not.
- **Contract stability.** An undocumented endpoint has no contract and no deprecation notice. Say so.
- **The evidence trail.** HAR, screenshots, command transcripts, descriptor captures, artifact hashes, firmware hashes, runtime receipts, and where they live. A finding whose receipt is gone cannot be re-verified.
