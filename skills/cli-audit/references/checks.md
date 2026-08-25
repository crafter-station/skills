# Checks

Every id emitted by `scripts/audit.sh`, what it means, and the line in `cli-build` it comes from. Nothing here was invented; a check with no source in `cli-build` does not belong in the script.

Statuses: `PASS` the property holds. `FAIL` a fact that becomes a finding once the conditional gates allow it. `NA` the check does not apply to this CLI. `SKIP` it applies but could not be run here.

## The machine contract

| id | Property | Source |
|---|---|---|
| `json-flag-present` | `--json` exists at all. | SKILL.md, "What agent-first actually means" |
| `nontty-implies-json` | Output format is decided from `isTTY` in exactly one place. Two or more means a per-command check, which drifts; the command that forgets is the one an agent hits. Only sites deciding *format* count: a TTY check guarding a prompt is a different property. | json-contract.md, "Non-TTY implies JSON, without a flag"; conventions.md, 3 builds |
| `json-not-overloaded` | `--json` takes no value. A declaration like `--json <payload>` means input, and an agent that learned the flag anywhere else passes it expecting output. | SKILL.md Phase 2; conventions.md, "Contradicted" |
| `schema-command-present` | A `schema` command exists so agents introspect at runtime instead of parsing `--help`. | SKILL.md; conventions.md, 3 builds |
| `schema-has-version` | That schema carries a version, so an agent can detect a contract change. Named in `cli-build` as the highest-value convention and the least adopted. | SKILL.md, "A `schema` command with a version field" |
| `next-steps-present` | Structured output names what can be run next. | SKILL.md Phase 2, "Add `nextSteps` to structured output" |
| `prompts-never-block` | Every file holding an interactive prompt also reads a TTY or non-interactive signal. **Not the same property as `--json`**: output shape and prompt behavior separate exactly where it matters, when a machine-shaped invocation comes from a real terminal. | SKILL.md, "No prompt ever blocks a non-interactive run" |
| `errors-on-stderr` | No error envelope is written to stdout. A caller doing `cmd > out.json` must not find the error in the file it is about to parse. | SKILL.md, "Data on stdout, diagnostics on stderr" |

## Scaffolded safety that is never wired

`cli-build` Phase 5: a feature is wired when its call site exists. Until then it is a definition, and `--help` describing it is a claim the code does not back. The probe is a grep for the call site; one hit, at the definition, means the feature does not exist.

This shape is **worse than having neither feature**, because the operator believes there is a paper trail and a preview when there is nothing.

| id | Property |
|---|---|
| `dry-run-wired` | `--dry-run` is read by a command body, not only parsed into a flags object. |
| `audit-log-wired` | The audit writer is called from outside its own definition. |
| `killswitch-wired` | The killswitch is consulted on a write path. |
| `audit-two-phase` | A pending state exists near the audit writer, so a process killed mid-flight leaves an orphan record instead of silence. |
| `presentation-helpers-used` | Every *rendering* helper a style or format module exports has a call site. |
| `truncation-centralized` | No hand-rolled `.slice(0, N)` on a value headed for the screen. |

The last two extend Phase 5's wiring rule from safety to legibility, which nothing else in this script covers. They came from a judgment pass, not from `cli-build`'s text: a CLI exported a correct `truncateVisible` (ellipsis, visible-width aware) with zero call sites while three places cut strings by hand, and shipped mid-word truncation that read as a rendering bug. The source looked solved.

Both are scoped deliberately narrow. The helper check ignores test seams and internal predicates, and the truncation check only counts slices inside a render path, because the first version flagged 21 sites where 3 mattered — and a check that fires on everything trains the reader to skip it, which is the same failure `cli-build` names about an oversized trust ladder.

Naming caveat, learned by getting it wrong: the audit writer's name is not a convention. Corpus CLIs call it `audit`, `appendAudit`, `writeAudit`, `logAudit`. Matching only the compound forms produced a false `NA` against a CLI with 29 call sites, and a false `NA` reads as a decided fact rather than a blind instrument.

## Packaging and distribution

| id | Property | Source |
|---|---|---|
| `shebang-portable` | The shebang names a runtime the installer will have. Naming a non-Node runtime gets `env: <rt>: No such file or directory`, a message with no cause and no fix. Measured: 6 corpus CLIs do this and 3 reached a registry, so it does not block publishing. | build-and-runtime.md; SKILL.md Phase 1 |
| `bin-is-built` | The bin entry is not raw TypeScript for an npm-published package. | build-and-runtime.md |
| `program-name-matches-bin` | The name the program calls itself equals the name that installs. Otherwise the Usage line in `--help`, the one string a reader copies verbatim, names a command they do not have. | human-output.md, "Help is the first screen" |
| `tests-exist` | Not published with zero tests. Minimum bar: auth flow, JSON contract per command, any signing code. | SKILL.md Phase 5; conventions.md, anti-patterns |
| `version-drift` | The checkout matches what the registry serves. | conventions.md, "Version drift between checkout and registry" |
| `home-override` | An `{APP}_HOME`-style override exists so tests do not write to the developer's real config and history. Convergent across 5 builds under 4 different names; every corpus CLI with real tests has one. | audit-log-patterns.md; conventions.md, 5 builds |
| `agent-manual` | `skills/<name>/SKILL.md` ships in the repo with `name` and `description` frontmatter, so the CLI installs with `npx skills add`. | SKILL.md Phase 6 |
| `secrets-not-persisted` | No password appears near a persistence call. Identifiers are stored; secrets come from the environment or a keychain. | SKILL.md, "Boundaries"; conventions.md, 2 builds |

`agent-manual` checks frontmatter validity, which is local. Installability is post-push and cannot be checked here: `npx skills add` failing for an unpublished repo is indistinguishable from a malformed SKILL.md unless you read the message.

## Runtime

These need `--bin` and the CLI on PATH. `cli-build` Phase 6 is explicit that running a source file verifies a file, while running the installed name verifies what ships: the bin entry, the shebang, the resolved dependencies, the banner. Three of those are invisible from a source invocation.

| id | Property |
|---|---|
| `bin-on-path` | The linked name resolves. |
| `bare-invoke-exit` | A bare invocation with a nonzero exit leaves stdout empty. The corpus found 810 bytes there that nobody had looked for, because bare invoke is not a case people test. |
| `stdout-clean-on-help` | `--help` under a pipe carries no ANSI. |
| `machine-mode-no-ansi` | `--json` output carries no ANSI, so an agent does not get escape bytes inside string fields. |
| `no-color-honored` | `NO_COLOR` changes styling only; the content is identical. |
| `failure-answers-as-data` | A command that ran and reached a negative verdict says so as a parseable document. Distinct from `errors-on-stderr` and only apparently in tension with it: an invocation that never ran (bad flag, missing argument) leaves stdout empty, while a command that ran and failed should not force the caller to parse English to learn why. |
| `exit-codes-meaningful` | An unknown command exits nonzero. Full separation of user error from system failure needs a forced system fault and is not probed. |

The last two come from `surfacer`, which encodes the same always-on list as Rust tests (`crates/surfacer-emit-cli/tests/agent_first_rules.rs` and `crates/surfacer-app/tests/agent_first_rules.rs`, seven tests each). That exercise is worth knowing about: applying the rules to the generator caught three violations, and applying the identical list to the generator's *own* CLI caught four more. Two independent encodings of one list will drift, so when a rule exists in both places, read the other before changing either.

## Coverage

`scripts/coverage.sh` is not a check. It walks the CLI's `--help` tree, counts leaf commands, and compares that against a list of what an audit exercised.

It exists because coverage is invisible in prose. This skill's own first run covered 4 of 80 leaf commands in sunat-cli and reported findings that read as a full pass; the gap surfaced only when the reader asked directly. The ratio is the fix.

Two parsing rules the walker learned the hard way, both from real `--help` output:

- **Anchor on the command column.** A wrapped description's continuation lines are indented deeper than the command name. Taking the first word of every indented line harvested `deuda`, `cambiar` and `presentado` as commands from one namespace, none of which exist, and then walked each as its own namespace: 159 namespaces reported for a CLI that has 23.
- **Count an entry only if it exists in the surface.** An `--exercised` line matching nothing is a typo or a stale note. Counting it inflates the very number the artifact exists to keep honest, so unmatched entries are reported separately.

## What the script will not decide

Emitted as `NA` with a pointer to SKILL.md step 3, so a clean run cannot be misread as a clean CLI. These are the rules from `human-output.md`, whose founding case is a CLI that passed every mechanical gate and was unreadable.

`human-default-view`, `metric-direction`, `scale-calibration`, `vertical-repetition`, `safety-sized-to-damage`, `noun-verb-consistency`, `dry-run-exercises-real-path`, `help-is-first-screen`.

One of these resists documentation. `human-output.md` records that the metric-direction inversion **came back in new code written after it was documented**: two columns titled "emptiest" and "selling fastest" both sorted the same field ascending, so each listed the opposite of its title. The defense that held was a named helper with regression tests, not a written rule. When an audit finds a directional metric, the finding is "extract a named helper and test it", never "document the direction".

## Checks not implemented

Present in `cli-build`, absent from the script, with the reason. Listed so the gap is visible rather than silent.

- **Audit record shape**: UTC ISO timestamp with millisecond precision, mode 0600, day-bucketed JSONL, shared id across the pending and final record, secrets redacted from `args`. Needs a live audit file to inspect, which needs a mutating run.
- **Intent tokens**: single-use via exclusive create (`wx`), short TTL, bound to a fingerprint of the specific operation. Only applies to the tiered ladder shape.
- **Consent gates**: no `--yes` escape, real TTY on both streams, refusal under `CI`, signed record so a backdated acceptance is detectable.
- **Atomic write**: temp file plus rename for state that must survive a crash mid-write.
- **`doctor`**: exists, makes a real authenticated call rather than checking file existence, emits per-check structured status, and its result is freshness-bounded so yesterday's pass cannot authorize today.
- **Exit-code distinctness** between user error and system failure. Needs a forced system failure.
- **`--fields` applied before the machine-mode branch**, and validated against one key space.
- **`--wait` and the job ledger**, for asynchronous APIs. Sourced in `cli-build` from published work rather than the measured corpus; report a gap here as a gap against a recommendation and say which kind it is.
