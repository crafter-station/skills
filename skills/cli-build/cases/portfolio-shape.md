---
measured: 2026-07
sample: 14 CLIs with real code
---

# Portfolio shape

Aggregate measurements across the CLIs this skill's conventions came from. Counts rather than rows, because the finding is the distribution and not which project sits where.

Three more projects have complete design documents and no code. They are excluded; a scaffold is not evidence.

## Distribution target

| Target | Built | Reached a registry |
|---|---|---|
| Runtime shebang, no build | 6 | 3 |
| Build step to Node | 4 | 3 |
| Compiled binary | 4 | 1 |

Building to Node has the best publish ratio. It is also the only target where a JavaScript developer installs nothing extra.

Worth knowing: three of the four published packages ship a runtime-specific shebang. Nothing stops that, and the failure mode lands on the user as `env: <runtime>: No such file or directory`, which names no cause and no fix.

## Feature coverage: present versus wired

**Present** means the code is in the repository. **Wired** means it runs and does what its name says.

| Feature | Present | Wired |
|---|---|---|
| `--json` output mode | 14 | 12 |
| `--dry-run` | 8 | 7 |
| Audit log | 9 | 7 |
| Real tests | 9 | 9 |
| `schema` command | 3 | 3 |

**The gap is the finding.** Two `--json` implementations are not output modes at all: they overload the flag to mean JSON *input*, which breaks the convention an agent arrives with. One CLI parses `--dry-run` into a flags object no command body reads, and imports an audit-log module nothing calls, while `--help` advertises both.

A feature that exists in code and does nothing at runtime is worse than an absent one. The operator stops watching.

**Wired** is the word for the difference, and grep is the test.

## Test coverage

Nine of fourteen have real tests. Of the five without, **two are published to a registry** and installable today.

Among those that do test, the range is wide: one has 27 files and roughly 3,500 lines, another has a single file per workspace package. The strongest suites cover the auth flow, the JSON output contract per command, and any signing code, which is also the minimum bar this skill recommends.

## Convention adoption

| Convention | CLIs using it |
|---|---|
| Non-TTY implies machine-readable output | 3 |
| Day-bucketed JSONL audit, restrictive mode | 4 |
| Two-phase audit around the mutating call | 3 |
| Signed single-use intent token | 2 |
| `schema` introspection command | 3 |
| Home-directory override for test isolation | 5 |
| Atomic write for state files | 3 |

Each of these appears in CLIs with no shared code, which is why they are treated as conventions rather than as one author's preference. See [conventions.md](conventions.md).

## What is not here

Per-CLI rows. This file used to be a table with one line per project, its features, and its defects in a Notes column.

That shape pairs a defect with a subject, which turns a lesson into an accusation, and the anonymization was thin: several of these are public packages, so a reader who wanted to map a row could. The aggregate teaches the same thing and names nobody.

Named cases still exist, written by the person who owns the code. See [README.md](README.md) for the boundary.
