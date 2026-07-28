# Testing a CLI

What a green suite fails to prove, drawn from a build where 59 passing tests and a clean typecheck sat on top of five real defects.

## Fixtures must cross a boundary the code orders or filters by

A date rollover, a month rollover, an empty set, a single-element list.

In that build, 54 tests all shared a single day of data. Underneath them, a command sorted by a formatted `DD/MM/YYYY` string, so a fifteen-day result set opened with next month's rows before today's. Every test verified the shape correctly and none could see the logic, because logic that only misbehaves across a boundary needs a fixture that crosses one.

A fixture set that never crosses a boundary tests the shape and not the logic.

## For any function whose failure mode is bad input, assert on the bad input

A test that only passes valid arguments cannot distinguish a validating implementation from a silently-dropping one.

The same build shipped a `--fields` that returned eleven empty objects under `ok: true` with exit 0 when given an unknown field name. The test passed `applyFields(rows, ["a", "c"])`, all valid, so it could not fail regardless of how unknown fields were handled. It tested the happy path of a function whose entire failure mode is the unhappy path.

A successful envelope containing nothing is the worst output an agent can receive: it reports success and carries no data, so nothing downstream knows to stop.

## A test suite never exercises the color path

Every runner executes without a TTY, so `shouldColor()` returns false and the styling functions return raw text. A green suite over a formatting layer proves the plain branch works and says nothing about the colored one.

That is why alignment bugs survive tests: the escape sequences that break column math are never in the string being asserted. To test alignment, inject the escapes into the fixture by hand, or assert on `visibleWidth` rather than `.length`.

## Test the built artifact, not only the source

Run the compiled entry point end to end and assert on exit codes. Assert on machine-mode output shape, which is your published contract. If you publish a binary, run the binary in CI on each target platform.

## The minimum bar

The auth flow, the JSON output contract per command, and any signing or crypto code.

Two packages in the corpus behind this skill have zero tests and are installable today.

## Smoke separately from units

For anything touching a real provider, a smoke script against the live target, kept apart from the unit suite and isolated by the `{APP}_HOME` override, is what proves the integration. Unit tests prove your code; only a live call proves your understanding of theirs.
