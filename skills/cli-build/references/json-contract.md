# The JSON contract

The output contract is the API agents depend on. Changing a field name breaks consumers silently; no type error, no failed build, just an agent reading `undefined` and improvising.

## Non-TTY implies JSON, without a flag

The highest-value default in this whole skill:

```ts
const machineMode = flags.json || !process.stdout.isTTY;
```

Three CLIs built independently arrived at exactly this. When output is piped or captured, nobody is reading colors and box drawings: emit JSON. An agent that forgets `--json` still gets parseable output instead of ANSI escapes.

**The clean implementation** is a framework-level hook rather than a check repeated in every command. With Commander, a `preAction` hook resolves an `--output auto` default once:

```ts
program.hook("preAction", (thisCommand) => {
  const opts = thisCommand.opts();
  if (opts.output === "auto") {
    opts.output = process.stdout.isTTY ? "table" : "json";
  }
});
```

The alternative, reading `program.opts()` inside all forty-odd commands, works and is what one corpus CLI does, but it drifts. One command forgets, and that command is now the one an agent hits.

## `--json` means output mode

Two CLIs in the corpus overloaded `--json` to mean *input*: in one, `--json` on a subcommand means "read answers from stdin as JSON"; in the other, `--json <file>` takes a path.

Both are defensible in isolation and both are wrong as a convention, because an agent that has learned `--json` from any other CLI will pass it expecting machine-readable output and get something else.

**If you need JSON input, name it for what it is:** `--input-json`, `--params`, `--from-json`, `--stdin`. Keep `--json` for output.

## `--params` as the canonical input interface

For commands with more than two or three inputs, accept a single JSON object:

```bash
{cli} order submit --params '{"ticker":"AAPL","amount":100,"side":"buy"}'
```

Sugar flags (`--ticker`, `--amount`) are convenience wrappers for humans. When both are present, `--params` wins, and that precedence is documented.

Why this matters for agents specifically: constructing a flag string invites conflicting combinations that pass argument parsing and mean something unintended. A single validated object has one shape, and it either validates or it does not.

## NDJSON: where it actually wins

The advice "prefer NDJSON over JSON arrays for streaming" is real but frequently overstated. In the corpus, exactly one CLI actually emits NDJSON. Four others emit a single pretty-printed JSON value for their primary output, and one wraps arrays in `[]`.

So state the actual rule:

- **One result:** a single JSON object. Simple, universally parseable.
- **A bounded collection you already have in memory:** an array is fine. `jq` handles it, agents handle it, and pretending otherwise adds friction for nothing.
- **A stream, an unbounded set, or incremental processing:** NDJSON, one object per line. This is where it genuinely wins, because the consumer acts on line one without waiting for the last.

Do not claim NDJSON in documentation unless you emit it. An agent told to expect line-delimited objects that receives a pretty-printed array will fail on the first parse.

## Shape

Pick an envelope and never deviate:

```json
{ "ok": true, "data": { }, "meta": { } }
{ "ok": false, "error": { "code": "AUTH_EXPIRED", "message": "...", "hint": "run `{cli} auth login`" } }
```

Or emit bare values with errors on stderr and a nonzero exit. Both work. **What breaks agents is inconsistency between commands**, one returning a bare array, another an envelope.

If you publish an envelope contract, it becomes the thing you cannot change casually. That is also why a published contract outranks any shared block that emits a different shape.

Errors carry three parts: a stable machine-readable `code`, a human `message`, and an actionable `hint` naming the command that fixes it. The hint is what lets an agent recover instead of reporting failure upward.

## `nextSteps`

Include, on stderr or in `meta`, what the caller can do next:

```json
{ "nextSteps": ["{cli} order submit --intent-token v1.abc.def"] }
```

This closes a loop `--help` cannot. After a preview, the agent has the exact next command with the token already substituted, instead of inferring it from documentation.

## `schema` as a first-class command

```bash
{cli} schema                    # list operations
{cli} schema order-submit       # one operation's input/output shape
```

This is the most consistently implemented agent-first convention in the corpus, present in three of the most mature CLIs. It beats stuffing schemas into a skill file, because runtime introspection cannot go stale relative to the code.

Where the schema comes from: bundled JSON schema files, a bundled OpenAPI document, or generated from the validation layer. All three appear in the corpus; the validation layer is the least likely to drift.

## `--fields` for context discipline

```bash
{cli} transcribe video.mp4 --json --fields text
```

Agents pay for every token of output. When a command returns a large object and the caller wants one field, a `--fields` flag saves real context. One corpus CLI added this specifically so agents could get a transcript without the metadata around it.

**Two hazards, both observed on the first real build with this skill.**

Apply the filter **before** the machine-mode branch, not inside the human-table one. Applied in the wrong branch it works for humans and is silently dropped for agents, which is exactly inverted.

And decide which key space it validates against. A table renderer usually relabels columns, so `--fields` faces two different key spaces the moment both modes exist: the JSON shape (`dateTime`) and the table headers (`hora`). Either validate against the mode in play, or keep the two key spaces identical. Silence on this produced an unknown field name returning empty objects with a success envelope.

## Third-party text is untrusted

Any free-text string that came from an external API; an error message, a description, a note field: can carry instructions aimed at the agent that reads your output.

Escape it before emitting. Never place it somewhere it reads as a directive. Two corpus CLIs treat this as a named, deliberate defense rather than incidental validation, and one goes further: before submitting, it verifies the provider's echoed preview literally contains the expected values, refusing on mismatch.

## Test the contract

The JSON output shape is the part most worth testing, and the part most often untested. A snapshot test per command over the machine-mode output catches accidental field renames, which are otherwise invisible until an agent breaks in production.
