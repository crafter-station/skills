# Audit log patterns

The audit log is the primary debugging tool for an agent-operated CLI. When something went wrong at 3am and nobody was watching, it is the only account of what happened.

Four CLIs in the corpus converged on the same design without sharing code. That convergence is the strongest signal in this document.

## The converged shape

**Append-only JSONL, one file per UTC day, restrictive permissions.**

```
~/.local/share/{app}/audit/2026-07-26.jsonl
```

```json
{"ts":"2026-07-26T14:22:01.003Z","id":"a1b2c3","cmd":"order submit","args":{},"result":"pending","phase":"pending"}
{"ts":"2026-07-26T14:22:01.847Z","id":"a1b2c3","cmd":"order submit","result":"ok","phase":"final","meta":{}}
```

Why each part:

- **JSONL, not a single JSON document.** Appending is one `write` with no read-modify-write, so a crash cannot corrupt earlier entries.
- **Day-bucketed.** Bounded file size, trivial retention, and "what happened Tuesday" is one file.
- **Mode `0o600`.** The log contains what was done to which account. It is not world-readable.
- **UTC.** Local time plus DST makes correlation across machines miserable.

## Two-phase writes

**Write the pending record before the mutating call, then the final record after.** Both share an id.

```ts
const id = auditStart({ cmd: "order submit", args });
try {
  const result = await placeOrder(order);
  auditFinish(id, { result: "ok", meta: result });
} catch (err) {
  auditFinish(id, { result: "error", error: serialize(err) });
  throw err;
}
```

The failure this exists for: the process dies between sending the request and receiving the response. With a single post-hoc write you have nothing, and no way to know whether the operation landed. With two phases you have a pending entry with no final, which is precisely the state that needs human investigation, and now it is visible.

An orphan pending record is a signal, not noise. Any reconciliation tooling should look for exactly that.

Three corpus CLIs implement this. One names the phases explicitly in the record; another puts `pending` in the result enum. Either works as long as an orphan is detectable.

## What goes in a record

| Field | Why |
|---|---|
| `ts` | ISO-8601 UTC, millisecond precision |
| `id` | Correlates the phase pair |
| `cmd` | The command as invoked |
| `args` | Inputs, **with secrets redacted** |
| `result` | `pending` / `ok` / `error` / `blocked` |
| `phase` | `pending` / `final`, if not implied by result |
| `trust` | The tier, when there is a ladder |
| `session` | Groups a run's operations |
| `error` | Serialized failure on the error path |

**Redact before writing.** Passwords, tokens, and full account numbers must not land in the log. It is a file that gets shared when debugging.

## Atomic writes for state that is not the log

The log appends, so it is safe by construction. Config and state files are not. A crash mid-write leaves truncated JSON that fails to parse on next start, and now the CLI is bricked.

**Temp file plus rename.** The rename is atomic on POSIX, so a reader sees either the old file or the new one, never a partial.

```ts
await writeFile(`${target}.tmp`, JSON.stringify(data));
await rename(`${target}.tmp`, target);
```

Three corpus CLIs do this, one of them hand-rolled with a comment explaining the data-loss avoidance. It is also available as a copy-paste block.

**Related: exclusive creation for single-use markers.** When a nonce or lock must be consumed exactly once, create the file with the `wx` flag. It fails if the file exists, making replay impossible at the filesystem level rather than via a check-then-write race.

## Home directory override, for tests

Every corpus CLI that has real tests has this, under four different names:

```ts
const home = process.env.MYAPP_HOME ?? join(homedir(), ".myapp");
```

Without it, tests write to the developer's real config and audit log, and a test run pollutes actual history. With it, each test gets a temp directory and the suite is hermetic.

Name it `{APP}_HOME`, document it, and use it for live smoke scripts too, not only unit tests. One corpus CLI ships smoke scripts against the real provider as first-class package scripts, isolated by exactly this variable.

## The anti-pattern

**A published CLI in this corpus imports an audit-log module and never calls it.** The import is there, the module is complete, and `audit()` appears nowhere outside its own definition. The same CLI parses `--dry-run` into a flags object that no command body ever reads.

Its `--help` advertises both.

This is worse than having neither, because an operator, human or agent, sees dry-run in the help text, believes a preview is possible and a trail is being kept, and stops checking. The first time a live write happens with no record, nobody knows it was unrecorded.

Unwired, in the sense the skill uses: the definition exists and nothing reaches it. Grep before claiming any safety property.

## Retention and size

Day-bucketing makes retention trivial: delete files older than N days, or compress them. Decide the policy and write it in the CLI's docs, because an append-only log on a busy agent-driven CLI grows without bound otherwise.

Provide an opt-out for environments where writing an audit trail is itself unwanted: an environment variable that disables logging entirely. One corpus CLI has this as a named kill switch. Default to on; make disabling explicit and visible.
