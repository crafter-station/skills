---
name: cli-audit
version: 0.2.0
description: "Audit an existing CLI against cli-build: how well an agent can operate it and how well a human can read it. Use when the user wants to audit a CLI, check whether a tool is agent-first, find out what a published CLI got wrong, grade a CLI's human output, verify that named safety features are actually wired, or prepare a patch list before improving an existing command-line tool. Reports findings with evidence; it does not patch."
---

# cli-audit

Audit a CLI that already exists against the rules in `cli-build`. The output is a findings list with evidence, not a score.

`cli-build` builds. This reads what was built and says where it drifted from what it claims.

## Why there is no score

The founding case of `cli-build`'s `human-output.md` is a CLI that **passed every mechanical gate and was unreadable**: 275 rows for someone who asked what was playing that evening, a percentage that read backwards, one title repeated fourteen times. No gate failed.

A number over that CLI would have read as healthy. That is the exact failure this skill exists to avoid, so it produces no number. A run yields three streams and they never merge:

| Layer | Decided by | Output |
|---|---|---|
| Deterministic | `scripts/audit.sh` | `PASS` / `FAIL` / `NA` / `SKIP` per check, with the evidence inline |
| Semi | script produces evidence, you read the verdict | finding or cleared, with the evidence quoted |
| Judgment | you, reading real output | finding or cleared, with the output pasted |

**A clean deterministic run is not a clean CLI.** Say that in the report every time, because the reader will otherwise take the passes as the answer.

Weighting these into one number needs thresholds calibrated against a distribution, and no such distribution has been measured. Inventing weights here would repeat the mistake `human-output.md` names about scale cutoffs: instinct-picked buckets that never discriminate. When enough CLIs have been audited to know the real spread, that is when a score becomes possible, not before.

## 0. Resolve the conditional gates first

Most checks in `cli-build` are conditional. Running all of them against every CLI reports absences as defects when they were deliberate decisions, which trains the reader to skim the findings. Resolve these before running anything, and write each answer into the report:

1. **Does any command carry consequence?** Money, irreversible writes, third-party side effects, personal data. If no: the entire trust-ladder group (audit log, `--dry-run`, killswitch, intent tokens, consent gates) is `NA`, and *its absence is compliant*. `cli-build` Phase 4 says so explicitly, and says the decision should be recorded rather than skipped. Look for that record before calling it an omission.
2. **Is there a human-facing surface?** If the user scoped the CLI machine-only, every judgment check from `human-output.md` is void.
3. **What is the distribution target?** Source shebang, npm, or native binary. The shebang and build checks only mean something against a declared target.
4. **Is the API asynchronous?** Gates `--wait` and the job ledger.
5. **Is it published?** Registry drift, zero-tests, and installer-shebang checks only bite once someone can install it.
6. **Contract origin: discovered, defined, or mixed?** Decides what the JSON contract is even measured against.

Everything sourced from `compounding-surface.md` (`--wait`, vocabulary in CI, `--deliver`, `feedback`) is labeled in `cli-build` itself as coming from published work rather than the measured corpus. Report a gap there as a gap against a recommendation, and say which kind it is.

**Done when:** all six are answered in writing, and the check groups they switch off are named.

## 1. Run the deterministic layer

```bash
scripts/audit.sh --repo <package-root> [--bin <installed-command>] [--json]
```

Without `--bin` only the static checks run and every runtime check reports `SKIP`. That is a materially weaker audit: `cli-build` Phase 6 is explicit that running a source file verifies a file while running the installed name verifies what ships — the bin entry, the shebang, the resolved dependencies, the banner. Link it first:

```bash
cd <package-root> && bun link   # or npm link
scripts/audit.sh --repo . --bin <name>
```

Read [references/checks.md](references/checks.md) for what each id means and where in `cli-build` it comes from. Every id traces to a line in the source skill; none were invented here.

**A `FAIL` is a fact, not yet a finding.** It becomes a finding when you have confirmed it applies given step 0. A `FAIL` on `home-override` in a CLI with no tests is noise.

**Verify every claim of absence before it reaches the report.** The first run of this skill produced four false absences out of five instrument bugs: an audit log with 41 call sites reported as "no audit log in this CLI", twice, under two different name guesses. A `FAIL` saying a feature is missing is the one output a reader cannot check cheaply, so it is the one that must be checked before it ships. Open the file and look.

The rule that came out of it: **a check that resolves a feature by guessing its function names will eventually announce that the feature does not exist.** Resolve the module, read the names it exports, then look for those names elsewhere. An export list cannot be wrong about itself.

Run the script against a second, unrelated CLI whenever you change it. Three of those five bugs were invisible against the CLI the check was written for and appeared immediately against another.

**Done when:** every non-`PASS` line is either promoted to a finding or dismissed with the conditional gate that excuses it, and every claim of absence has been confirmed by reading the code.

## 1b. Measure coverage, before and after

```bash
scripts/coverage.sh --bin <name> --max-depth 4
```

This walks the CLI's own `--help` tree and reports how many leaf commands exist. Run it **before** the judgment layer so you know the size of the job, and again at the end with the list of what you actually ran:

```bash
scripts/coverage.sh --bin <name> --max-depth 4 --exercised exercised.txt
# Coverage of sunat-cli: 27 of 80 leaf commands exercised (33%)
```

`exercised.txt` holds one command per line as invoked, without the binary name. Entries matching no command in the surface are counted separately and reported, because a stale note silently inflating coverage is the failure this artifact exists to prevent.

**The ratio goes in the report.** An audit of four commands and an audit of sixty produce prose that reads identically; this session's first pass covered 4 of 80 and the gap surfaced only because the reader asked. A number the report cannot omit turns partial coverage from a disclaimer into a fact.

Low coverage is often correct — most of what goes unexercised in a consequential CLI is the write path, and not running it is the right call. Say which it is: deliberate, or not reached.

**Done when:** the surface size is known before judging, and the final ratio plus the not-exercised list are in the report.

## 2. Run the semi layer

These need evidence a script can produce and a verdict only a reader can give.

- **Noun-verb consistency.** Dump the surface (`<cli> --help`, or the `schema` command), list every noun-verb pair, and look for the verb the rest of the surface does not use. `info` where everything else says `get` costs an agent a `--help` round trip.
- **`--dry-run` exercises the real path.** Run it twice with different valid inputs. If the output does not vary with the input, it is a hardcoded shape and proves nothing. The strongest corpus implementation calls the provider's own preview endpoint.
- **Third-party free text is escaped.** Anything a remote API returns as prose can carry instructions aimed at the agent reading your output. Find where provider text reaches stdout and check what escapes it.
- **The emitted example runs.** When output prints a next command, copy it verbatim into the shell. An emitted example is an executable promise.
- **Tests assert on bad input.** A suite that only passes valid input proves the happy path. Check that the input-validating functions have a case passing something unknown.
- **The color path is tested with escapes present.** Without a TTY every style function returns plain text, so the escapes that break column arithmetic never appear in the asserted string. Forcing color is not enough either: the test passes trivially if the fixture carries no escapes. The assertion that holds is `.length > visibleWidth`.

**Done when:** each applicable item is a finding with its evidence quoted, or cleared with what you ran.

## 3. Run the judgment layer

Run the CLI and read its real output. Not `--help`, not the tests: the output a person gets. Read it twice, once for correctness and once as someone who does not know the domain.

Read [cli-build's human-output.md](../cli-build/references/human-output.md) with the terminal open, and ask its questions against what is on screen:

- What does the biggest number mean, and what does a reader assume when it is high? If they assume the opposite, the metric is mispresented even though it is correct.
- Is there a column where every row says the same thing? That is a heading that has not been promoted.
- Does the default view answer the question a person asked, or return what the API returned?
- Are the scale thresholds calibrated against this data, or against round numbers? A bucket that never fills and a bucket holding 84 percent both look like they are working.
- Is red used for anything that is not an error?
- Does `--help` read as the first screen of the product, or as a reference appendix?

**One rule here cannot be fixed by writing it down.** `human-output.md` records that the metric-direction inversion came back in new code written *after* it was documented. The defense that held was a named helper with regression tests. When you find a directional metric, the finding is not "document the direction" — it is "extract a named helper and test it."

**Done when:** the real output has been read and pasted into the report, and each question above is answered against it.

## 4. Report

Group findings by what it costs to fix, not by which layer found them. The reader wants to know what to patch, and the layer is provenance.

Every finding carries:

- **what**, in one sentence;
- **the evidence**, as the command run and its output, or `file:line`;
- **the rule it violates**, cited to `cli-build`;
- **the class**, so the reader knows whether a script re-checks it or a person does.

Two things the report must say out loud:

1. **What was not checked, and why.** A conditional gate that switched a group off, a runtime check that reported `SKIP` because the CLI was not linked. Silence about a skipped group reads as a pass.
2. **That a clean deterministic run is not a clean CLI.** With the reason: machine-readable and legible are independent properties and only one of them has rules a script can run.

Write the report to `reports/<cli-name>-<date>.md` in this skill, so the next audit of the same CLI can diff against it.

**Done when:** the report exists, names its own blind spots, and every finding cites evidence that can be re-run.

## Boundaries

**This skill reports; it does not patch.** Auditing and fixing in one pass loses the record of what was wrong, and the record is what makes the next audit cheap. Patch in a separate cycle, against the report.

**Adoption is not a check.** Whether a CLI uses `cligentic` blocks measures adoption, not quality. `cli-build` Phase 3 accepts a rejection with a reason, and names the strongest one: a published output contract outranks a shared block. Penalizing a reasoned rejection would contradict the skill being audited.

**Findings about someone else's package drop the subject and keep the defect.** A case about a CLI Hunter wrote can be specific about what broke. See `cli-build`'s `cases/README.md`.
