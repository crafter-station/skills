# Terrain playbooks

Eight terrains, each with the technique that actually worked.

Terrains A through G come from 21 recon reports across public APIs, private GraphQL, government portals, LMS platforms, BaaS apps, file formats, and desktop binaries. Terrain H comes from separate work characterizing an on-device neural accelerator, and it is the newest of the eight.

The terrain is not the tech stack. It is **how much is documented and whether you can log in.** Those two questions predict the work better than REST-vs-GraphQL ever does.

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

**Technique, in order:**

1. **Read the literature before touching the device.** Somebody has probably already characterized it. A published constraint catalog saves days of bisection, and citing it is faster and more accurate than rediscovering it.
2. **Enumerate what is actually present.** The OS knows more than the docs: device trees and registries, connected-device listings, driver and firmware versions.
3. **Find the acceptance boundary by submitting work.** For an accelerator this is the compiler or the runtime: export a real workload and count how many operations get rejected or silently fall back to another unit. A zero-rejection export is the receipt that your understanding of the constraints is complete.
4. **Measure per unit, not in aggregate.** A device that reports one number hides where the work went. Power and throughput broken out by compute unit is what tells you whether the accelerator ran your workload or quietly handed it to the CPU.
5. **Replay against a baseline on the same silicon.** "Faster" means nothing without a same-size comparison measured on the same machine under the same load.

**What this looks like when it works:** one corpus target was an on-device neural accelerator whose real nature contradicted the mental model everybody uses. Advertised as a general scheduling option, it turned out to be a fixed-function convolution engine where one operation class runs several times faster than the one most models are built around. The report that matters was not a list of endpoints, it was a constraint catalog: which activation, whether bias is allowed, which memory layout, which operation set. Verified by a full export landing zero rejections, and by per-unit power measurement showing the accelerator drawing less power at higher throughput than the alternative.

**Gotchas specific to this terrain:**

- **Silent fallback is the failure mode.** Unlike a web API, a device rarely errors. It accepts the work and runs it somewhere slower. Always verify *where* it executed, never assume from the absence of an error.
- **Separate what you measured from what you read.** A published catalog is a citation, not your finding. Keep them distinct in the report; conflating them is how a paper's claim becomes your unverified assumption.
- **The constraint set is versioned by silicon.** A rule true on one generation can be false on the next. Record which chip, OS, and toolchain version the measurement came from.
- **Aggregate metrics lie.** Total power and wall-clock time cannot tell you which unit did the work.

Both this terrain and Terrain F end in the same place: the report is a set of rules the implementer must satisfy, not a table of endpoints to call.

---

## Cross-terrain: what always goes in the report

Regardless of terrain:

- **Auth flow, observed.** Header names verbatim. Token lifetime. Whether anything rotates.
- **Rate limits, as measured.** If no limit headers appeared and you did not probe, write "no limit headers observed, not measured". Do not invent a number. Six corpus reports all adopted the same polite default without measuring, which reads like evidence and is not.
- **Contract stability.** An undocumented endpoint has no contract and no deprecation notice. Say so.
- **The evidence trail.** HAR, screenshots, bundle hashes, and where they live. A finding whose receipt is gone cannot be re-verified.
