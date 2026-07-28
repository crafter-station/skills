# Human output

The rest of this skill treats the human as the agent's supervisor. This file treats the human as a reader, which is a different job with different failures.

Worth naming the gap that produced it: the first CLI built with this skill passed every gate here (stable contract, wired flags, verified output) and was unreadable. 275 rows for someone who asked what was playing that evening, a percentage that read backwards, and the same title repeated fourteen times. **No gate failed.** Machine-readable and legible are independent properties, and only one of them had rules.

These came from watching real output in a terminal and hearing which parts were hard to read.

## The number must mean what the eye assumes

An upstream exposed *available* seats. Printed as-is, a nearly empty room showed `98.8%` and a full one `25.9%`. Correct, and read backwards by everyone, because a high percentage next to a resource name reads as "full".

The fix was not inverting the number. It was changing representation: a bar that grows with what is sold, plus a word. A bar has no ambiguous direction and a word needs no interpretation.

**Before showing a metric, ask what a reader assumes when the value is high.** If they assume the opposite of what it means, the metric is mispresented even though the number is right.

**A written rule is not enough here.** The same inversion came back later in new code written *after* this was documented: two columns titled "emptiest" and "selling fastest" both sorted by the same field ascending, so each listed exactly the opposite of its title. It looked correct until someone read the numbers.

When a field has a counterintuitive direction, the defense that holds is a **named helper with a test**, not a document. A hand-written `sort` at each use site invites the wrong sign every time; one function with a name and three regression tests gets it wrong once.

## Calibrate thresholds against the real distribution

Scale cutoffs picked by instinct (20/50/80) produced a column where the top bucket was **never used** and 84 percent of rows landed in a single bucket.

A column where almost everything says the same thing does not inform, and worse, it looks like it is working.

Recalibrated against the actual percentiles, all four states appear and the column discriminates again.

**A visual scale is calibrated against the distribution it will cross**, not against round numbers that sound reasonable. This is the same failure as a fixture that never crosses a boundary: the code looks fine because nothing tests it.

## The human default is a design decision

The human view's default is not whatever the API returned. 275 rows is the API's answer; "what is playing tonight" is the question. Decide what the default view shows, and let flags widen it.

Two audiences, two defaults. The machine mode returns everything because the agent filters. The human mode returns what a person asked for.

## Vertical repetition is a heading

The same value repeated down a column is a heading that has not been promoted yet. Fourteen rows carrying the same title is fourteen chances to read it and zero information after the first.

Group it, print it once, and let the rows carry only what varies.

## Split by actionability, not by the backend's taxonomy

**The backend's taxonomy is not the visual hierarchy.** Categories that exist because a database has that column will group things a reader does not need grouped, and separate things they need side by side.

Ask what the reader will do with the output, then group by that.

## Urgency measured beats raw state

"Opens on the 29th" is a fact. "Opening day is 33 percent sold and the 7pm show is nearly out" is a decision.

Where the data supports it, print what the number means for the reader rather than the number alone.

## Emit the command, not the argument

When output points at a next step, print the runnable command with the values substituted, not the value the reader must paste into a command they reconstruct.

That is the human-facing twin of `nextSteps` in [json-contract.md](json-contract.md), and it has the same reason: the reader should not have to rebuild the invocation.

An emitted example is an executable promise. If you print it, it must run.

## Help is the first screen

For most people `--help` is the whole product until they run something. It is not a reference appendix; it is the first thing they read and often the only thing.

## Drawing a grid: choose the glyph by where it sits in the cell

A character that draws well alone can break a grid when it renders wider or narrower than a cell. Pick glyphs by how they behave in the layout, not by how they look in isolation.

**And check the other axis.** A layout verified by column can still fail by row, or the reverse. Aligning one axis is not aligning the grid.

**An axis header only helps when the axis is homogeneous.** If rows carry different units or scales, a shared header labels a relationship that does not exist.

## A derived legend cannot go stale

A legend written by hand drifts from the thing it explains the first time either changes. One derived from the same source as the display stays correct by construction.

## A state that varies between responses is not an attribute

If a value can differ from one call to the next, presenting it as a property of the entity is a lie with a long shelf life. It belongs where the reader can see it is a snapshot.

## A preview that shows the input is not a preview

Echoing what the user typed proves parsing worked and nothing else. A preview shows what *would happen*, which means it has to run the real path.

Same rule as `--dry-run` in Phase 4, applied to human-facing output.

## Upstream communicates operational state in free text

Providers announce maintenance, queues, and outages in prose meant for humans. Parse for those, surface them, and treat the text as untrusted before it reaches your output.

## What does not change

None of this touches machine mode. `--json` stays the stable contract, and every rule here applies to the branch a person reads.

The two modes diverge on purpose: the agent gets everything and filters, the human gets what they asked for. Building one output for both produces something that serves neither.

## A test suite never exercises the color path

`bun test`, `vitest`, and every other runner execute without a TTY, so `shouldColor()` returns false and every styling function returns raw text. A green suite over a formatting layer proves the plain branch works and says nothing about the colored one.

That is why alignment bugs survive tests: the escape sequences that break column math are never in the string being asserted. To test alignment, inject the escapes into the fixture by hand.

Same family as a test that only passes valid input: it cannot fail in the way the code fails.

## The check this file adds

The skill's Phase 6 says to run the command and read the output. That criterion caught real defects, and it is not sufficient on its own, because "the output is correct" and "the output is readable" are different questions.

**Read the human output as someone who does not know the domain.** What does the biggest number mean? What is the first thing the eye lands on? Is there a column where every row says the same thing? Those questions have answers a typecheck cannot produce.
