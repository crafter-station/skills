# The IR target

`surfacer` is a compiler. It reads one `.surfacer.json` file, a `SiteDescriptor`, and emits six interfaces from it: a Rust shim, a just-bash runner, help text, a TypeScript CLI, an OpenAPI 3.1 document, and an MCP server. It does no recon of its own. The IR is the only input, so whoever writes the IR decides what all six interfaces contain.

This skill is that writer. Recon already establishes what a target exposes and which of it was actually observed; the IR is that same finding in the shape a compiler can consume. The markdown report is for a human deciding whether to build. The IR is for a machine that builds.

Emitting one is optional. Produce it when the target has an HTTP surface and the user wants something built against it, which in practice means recon ended in "build it" or "build it narrowly". A report that ends in "do not build yet" has nothing to compile.

## The one rule, again, harder

**Only what you observed goes in the IR.** Inference, bundle-grepped routes, endpoints from stale docs, and everything under "Needs verification" stay in the markdown and never reach the JSON.

The report can afford a `Verified` column because a human reads the column. The IR has no such column, and that is deliberate rather than an omission. Every field in `SiteDescriptor` is read as fact by six emitters and by `surfacer check`, which re-probes the first three endpoints in `http.endpoints` against the origin of `meta.sourceUrl` and compares the response signature to a stored fingerprint. That is the drift check: it tells the user their installed CLI no longer matches the site. Put an inferred path in the IR and the drift check fires on an endpoint that never existed, which trains the user to ignore it. One invented row costs the credibility of the whole mechanism.

This constraint is what makes an agent-authored IR safe to consume. A deterministic crawler could only record what it saw; an agent can write anything, so the discipline has to be explicit. When in doubt, the endpoint stays in the report and out of the IR.

## What each field is filled from

### meta

| Field | Filled from |
|---|---|
| `siteName` | The short slug the user will type as a command. Lowercase, no spaces. This becomes the shim binary name and the directory under `~/.surfacer/sites/`. |
| `displayName` | The target's own name for itself, as it appears in the report title. |
| `sourceUrl` | The URL you actually captured against, not the institutional landing page. `surfacer check` derives the drift-probe origin from this, so a marketing domain here makes the check probe the wrong host. |
| `irVersion` | The IR schema version, `"0.1.0"`. Every descriptor in the surfacer tree carries this string. It also becomes the `info.version` of the emitted OpenAPI document. |

### provenance

`generatedAt` is an RFC 3339 timestamp. `probeDurationSec` is how long recon took in whole seconds, which is honest metadata about how much looking produced this surface rather than a quality score.

`technique` records how the surface was mapped. Write `agent` for an IR produced by this skill, whatever terrain it came from. The other values, `http`, `ax`, and `hybrid`, describe a mechanical probe, and the distinction matters downstream: a mechanical probe repeats its own output, while an agent naming commands and writing descriptions does not. A consumer deciding how much to trust a regenerated IR needs to know which one it is holding, and `surfacer check` reads this field to decide what to tell the user when it detects drift.

`classifierBucket` is a string, and surfacer's own classifier uses these names: `FormSessionLegacy`, `RestModernSpa`, `GraphqlIntrospectable`, `AxOnly`, `HtmlRendered`, `Hostile`, `Inconclusive`. Reuse them, because a bucket nobody else writes cannot be grouped with anything. The mapping from terrain is close but not identical: Terrain B is usually `RestModernSpa`, Terrain C is usually `FormSessionLegacy`, and a target that fought back the whole way through is `Hostile` regardless of terrain.

### http.endpoints

One entry per distinct request you drove and can attribute to an action. `path` is the path portion only; the origin lives in `meta.sourceUrl`.

`method` serializes SCREAMING_SNAKE_CASE: `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `HEAD`, `OPTIONS`.

`operationKind` follows the method unless the target contradicts it. `GET`, `HEAD`, and `OPTIONS` are `read`; the rest are `write`. The exception is common enough to expect: a form-session portal that runs every query as a `POST` has `read` operations behind `POST` endpoints, and the kind is what the emitters use to decide what is safe to call. Classify by what the request does to the target, not by its verb.

`namespace` is the grouping the command path is derived from, and `sampleRequestContentType` and `sampleResponseContentType` are the content types you observed on that one request. `application/x-www-form-urlencoded` in and `text/html` out is a normal answer for a legacy portal, and recording it saves the implementer from assuming JSON.

### params, and why every flow runs twice

`ParamDescriptor` is `{name, varies, example, observations}`, and three of those four fields only mean something across multiple observations:

- `observations` is how many requests to this endpoint carried the parameter. One observation means you saw it once; it does not distinguish required from incidental.
- `varies` is true when the parameter carried a different value across observations. The IR's own comment calls this the strongest available evidence that a caller controls it, and that is exactly right: a parameter that stayed identical across two different inputs is more likely a constant the client always sends, while one that changed is one the user supplies.
- `example` is a value you actually saw, and it is shown to the user in help text. It must be a real observed value, never a plausible-looking one, and never a session token or anything else identifying.

This is why Phase 2 requires driving each flow twice with different inputs. That instruction exists in the skill already, to separate a parameter from a path segment. Filling `varies` honestly is its second payoff: run a flow once and every parameter is `varies: false`, which tells the emitters that nothing is caller-controlled and produces a CLI with no useful flags. The two runs are what turn a capture into a command surface.

A parameter you never saw vary is still written, with `varies: false`. Absence of variation is a real observation. Inventing variation you did not see is not.

### operations

An operation is a command. `transport` points at an endpoint by index into `http.endpoints`, so the operations array and the endpoints array are separate on purpose: two commands can share one endpoint with different parameters.

`summary` is one line for a list. `description` is the sentence shown in help, and `lint_ir` rejects it empty.

`commandPath` is the noun-verb path a user types, as an array: `["invoice", "list"]` becomes `invoice list`. Noun first, then verb, matching what `cli-build` designs. Derive it from `namespace` and the action, in kebab-case.

**`lint_ir` rejects duplicate command paths**, comparing the array joined by spaces. This is not a formality. Real targets collapse into collisions: SUNAT has seven distinct operations that all normalize to `operatividadaduanera novedades`, and the IR crate documents that case in `unique_command_names`, which suffixes duplicates numerically so emitters do not produce ambiguous names. That function is a floor for emitters, not permission to ship collisions. A command path that needs a numeric suffix to be unique is one the user cannot guess and cannot remember. When two operations collide, distinguish them by what they actually differ in, usually the resource or the filter, and give each a name a person could type on purpose.

### auth

`http.auth` is the surface default, applied to every operation that does not override it. An operation's own `auth` field overrides it, and `Some(none)` is how you say one endpoint is public on an otherwise authenticated surface. Omitting auth entirely at both levels means the surface was reached unauthenticated.

There are four modes, internally tagged by `kind`:

**`none`.** Reached without credentials. Explicit, so an operation can opt out of a surface default.

**`apiKey`.** A static secret the caller already holds, sent on every request. `location` is `header` or `query`, `name` is the header or parameter name, `valuePrefix` is a prefix like `"Bearer "` and is omitted for a bare key. Covers long-lived bearer tokens as well as literal API keys.

**`oAuth2`.** The client acquires the token itself, headless. `grant` is `password`, `clientCredentials`, or `authorizationCode`. `tokenUrl` is the token endpoint you observed. `scopes` are the scopes seen on the token request. `ttl.seconds` comes from an observed `expires_in`, and `ttl.onExpiry` is `reacquire`, which is valid here because no human is needed.

**`browserBootstrappedToken`.** A token only the target's own browser session can mint, captured once and replayed headless until it expires. Acquisition and use are separate objects because they happen in different processes: `acquire` names the `loginUrl` and how the token becomes observable, `use` names how it is attached afterward, and `ttl` names how long it lasts. `capture` is one of `requestQueryParam` (with `urlContains` and `param`), `responseHeader` (with `urlContains` and `header`), `cookie` (with `name`), or `storage` (with `store` of `local` or `session`, and `key`). Its `ttl.onExpiry` is `promptReauth`, because re-acquiring requires a human at a browser and `reacquire` would promise something the client cannot do.

Not every mode survives every emitter intact, and the one that does not is worth knowing before you write it. OpenAPI 3.1 has no security scheme for a browser-minted token replayed headless, so the OpenAPI emitter carries the whole auth object in an `x-surfacer-auth` extension, leaves the operation out of `security`, and adds a line to its description telling the reader to run `surfacer auth login` first. The spec that comes out has `securitySchemes` absent rather than a scheme that lies about how the target authenticates. That is the emitter degrading honestly, not dropping your auth, and it is the correct output for that mode.

**The secret is never in the IR.** `secretRef` names where the client reads it: `{"from": "env", "var": "..."}`, `{"from": "file", "path": "..."}`, or `{"from": "acquired"}` for a value produced at runtime. The IR is meant to be committed, and this is the rule that keeps it committable. The same discipline that keeps the HAR out of version control keeps its contents out of this file.

Map only what you completed. An auth flow you read but never ran is a hypothesis, and a hypothesis in the `auth` field produces six interfaces that cannot log in. If you never authenticated, the honest IR has no auth at all and covers only the endpoints you reached without it.

### extractor

Optional, and only worth filling when the response is HTML you had to parse rather than structured data. `list` describes a repeated item with an `itemPattern` and `fields`, `detail` describes a single record's fields, and `raw` says the body is handed through untouched. Every field names a `source`, either a CSS selector or an accessibility-tree role. Leave it out when the response is JSON.

## Which terrains produce an IR

**A, official documented API.** Produces the cleanest IR, since the spec names paths, methods, and parameters. The observed-only rule still binds: a spec is documentation, not observation, and specs are routinely incomplete or stale. Include the endpoints you exercised against the live service. For the rest, the OpenAPI spec already exists and the user should use it directly.

**B, private API behind a SPA.** The intended case. JSON endpoints, driven twice, with real parameter variation. This is what the IR was designed around.

**C, portal with credentials.** Produces an IR with auth, usually `browserBootstrappedToken` or `apiKey` depending on how the session is carried. Often `FormSessionLegacy`, `POST` endpoints doing `read` work, and `text/html` responses that need an extractor.

**D, portal without credentials.** Produces no IR. Without credentials nothing behind the wall was observed, and an IR of the login page is six interfaces for logging in. This matches the skill's existing position that Terrain D yields a list of unknowns; a list of unknowns has nothing to put in `operations`, and `lint_ir` rejects an empty `operations` array.

**E, SPA on a BaaS.** Produces an IR only for calls you actually made. The bundle names tables and columns, which is schema rather than observation, and row-level security means the bundle's shape is not what your key can reach. What you read from the bundle goes in the report. What you called goes in the IR.

**F, no backend.** Produces no HTTP IR. There is no server to describe, and `http.endpoints` would be empty, which `lint_ir` rejects as an empty HTTP surface. The report's schema section is the deliverable.

**G, desktop app or binary.** Produces an IR when the app talks to a backend you observed over its debugging port, following the Terrain B rules. Local-only IPC has no HTTP surface.

**H, hardware or an accelerator.** Produces no IR. The finding is a constraint set on a compiler or runtime, not a set of endpoints, and none of the IR's fields can carry it.

## Writing and validating

Write to `recon/{siteName}.surfacer.json`, alongside the report. `surfacer install` copies an IR into `~/.surfacer/sites/{siteName}/ir.json`; the recon output is the source artifact, not the installed one.

The gate before handing it over:

```bash
surfacer lint recon/{siteName}.surfacer.json
```

It prints `✓ Valid IR` with the operation, endpoint, and technique counts, and exits non-zero listing every error otherwise. It checks that `siteName` is non-empty, that there is at least one operation, that no `commandPath` is empty or duplicated, that no `description` is empty, that a declared HTTP surface is non-empty, and that no endpoint `path` is empty.

Read the counts, not just the checkmark. Lint is a schema check and cannot tell an observed endpoint from an invented one, so a valid IR with more endpoints than the report's observed rows is the signal that inference leaked across. The count in the lint output should match the count of observed rows in the report's endpoint table. That comparison is the only automatic defense the observed-only rule has.

Ship the IR with the report and the friction log. It is a claim in the same document set, held to the same standard: everything in it was seen.
