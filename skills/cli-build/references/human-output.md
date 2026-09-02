# Human output

The rest of this skill treats the human as the agent's supervisor. This file treats the human as a reader, which is a different job with different failures.

Worth naming the gap that produced it: the first CLI built with this skill passed every gate here (stable contract, wired flags, verified output) and was unreadable. 275 rows for someone who asked what was playing that evening, a percentage that read backwards, and the same title repeated fourteen times. **No gate failed.** Machine-readable and legible are independent properties, and only one of them had rules.

These came from watching real output in a terminal and hearing which parts were hard to read.

## Default scope

Treat polished human output as part of the product unless the user explicitly asks for an MVP, minimal, headless, or machine-only CLI. Do not infer reduced scope from a small number of commands. A two-command tool can still feel unfinished when it has no hierarchy, no progress, and no distinction between success, warning, error, and context.

The default human surface includes:

- a compact TTY-only banner when the CLI has an interactive entry point;
- semantic color and emphasis with a clear visual hierarchy;
- readable tables that remain aligned after styling;
- real progress for operations whose completion can be measured;
- plain output under `NO_COLOR`, pipes, and machine modes.

This is a presentation default, not permission to add every safety mechanism. Safety remains proportional to damage. Human output remains separate from the stable machine contract.

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

## Drawing a grid: overview first, identifiers on demand

A grid overview answers shape, position, density, and state. An identifier answers which exact object to act on. Printing every identifier in the overview makes each cell wider and can turn a spatial diagram into a spreadsheet.

Use one compact, fixed-width cell per object in the default human view. Preserve empty coordinates because gaps and aisles are part of the geometry. Reveal identifiers in a focused row, drill-down, interactive selection, or explicit flag when the reader needs to act on one object. Machine mode keeps the structured coordinates, identifiers, and states.

Choose the cell representation by what it means, not by how it looks in isolation:

| Representation | Best fit | Failure mode |
|---|---|---|
| `◼◼` or another narrow geometric glyph | Discrete objects in an overview | Unicode width still needs verification in the target terminals |
| `██` | Continuous magnitude or an area meant to touch | Adjacent rows can merge into vertical bars when used for discrete objects |
| `[27]` | An identifier in selection or detail mode | Four visible columns per object overwhelm a large overview |
| `##`, `[]`, or another fixed-width ASCII fallback | Environments where Unicode width is uncertain | Less visual fidelity, but predictable alignment |

`◼`, `█`, and `■` are Unicode, not ASCII. The examples are tradeoffs, not a mandated palette. Decide the visible width budget first, then test the chosen glyph with the same width function and terminals used by the CLI. Two characters often make a terminal cell look square because terminal cells are usually taller than they are wide.

Color can carry state without making every cell wider, which is why it works well in a dense overview. It cannot be the only carrier. Define each state once with its color, colored glyph, plain glyph or short label, and legend text. Render the map and derive the legend from that same definition so they cannot drift apart.

When color is unavailable under `NO_COLOR`, a pipe, an unsupported terminal, or an accessibility preference, preserve the geometry and distinguish states with different plain glyphs or labels. A reader should still be able to tell states apart after the ANSI escapes are removed. Do not hard-code a universal palette: state meanings are domain-specific, and the important invariant is that the mapping is consistent, contrast is sufficient, and every state present is explained.

Render geometry deterministically from structured coordinates. Do not infer position from display labels or ask an agent to redraw the layout from prose. A deterministic renderer owns spacing, orientation, and state; an agent can choose the mode or summarize the result.

**Check both axes.** A layout verified by column can still be mirrored or inverted by row. When one provider axis needs reversal, verify the other against a real reference before trusting the map.

**An axis header only helps when the axis is homogeneous.** If rows use different numbering or scales, a shared header labels a relationship that does not exist. Put identifiers inside their cells in the explicit detail mode instead.

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

## Color, emphasis, and aligned columns

For a human-facing TypeScript CLI, adopt Cligentic's `detect`, `style`, and `banner` blocks by default. The colors are the easy part; what gets written wrong is the width and the stream boundary. Follow the canonical Cligentic skill for installation and transitive dependencies.

```bash
bunx --bun skills add Railly/cligentic --skill cligentic
```

`"\x1b[1mHi\x1b[0m".length` is 12 and its width on screen is 2, so any column alignment using `.length` on styled text is off by the size of the escapes. The block ships `visibleWidth`, `padVisible`, `padStartVisible`, and `truncateVisible` for exactly that, plus `bold`, `dim`, `italic`, `underline` and a 256-color semantic set (`danger`, `warn`, `ok`, `info`, `muted`).

Three decisions in it worth knowing, because they are the ones you would get wrong writing it fresh:

- **One place consults `shouldColor()`.** Styling applied per call site is styling that leaks into a piped stream the first time someone forgets the check.
- **256-color, not the basic 8.** Basic red and green render as whatever the user's theme assigns, which on a light terminal can be unreadable and on a themed dark one indistinguishable from each other.
- **Semantic names over color names.** A call site reads as intent, and the palette can change without touching it.

**What to emphasize, not how.** The block gives you the verbs; deciding where they go is the work in this file. Bold the thing the eye should land on first, which is usually a header or the one row that demands action. Dim what is context: separators, units, values a reader scans past.

**Color carries a state with an ordering, and errors are the state that must have one.** The mapping worth defaulting to:

| Verb | State |
|---|---|
| `danger` | An error, and every error. Nothing else. |
| `warn` | Something irreversible is about to happen, or a dry run stands in for it |
| `ok` | An operation completed |
| `info` | A value that departs from the default and the reader should notice |
| `muted` | Context: separators, units, hints, anything scanned past |

The failure this prevents is specific and was observed. One CLI used amber for warnings, green for success, and blue for a non-default badge, and printed its errors as plain `Error: message` with no color at all. The most important state it reported had no signal while a format badge had one, and the only use of red in the codebase was a red checkmark on logout, where the glyph said success and the color said failure.

Two rules fall out of that:

- **The glyph and the color must agree.** A red `✓` asks the reader to resolve a contradiction that has no answer.
- **Outside a bounded data visualization, reach for red only for errors.** A grid or chart may use a local categorical palette for domain states when its legend makes the scope explicit. Global diagnostics still keep their semantic palette, and the same screen must not leave the reader guessing whether red means a data state or a failure.

An error line reads best as three levels: the word in `danger`, a searchable code `muted` beside it, the message plain, and the hint `muted` on its own line, because the hint is the way out rather than the problem.

A color used decoratively spends the reader's only channel for urgency.

And every rule above still applies underneath. A colored column that reads backwards is worse than a plain one that reads correctly.

## A test suite never exercises the color path

`bun test`, `vitest`, and every other runner execute without a TTY, so `shouldColor()` returns false and every styling function returns raw text. A green suite over a formatting layer proves the plain branch works and says nothing about the colored one.

That is why alignment bugs survive tests: the escape sequences that break column math are never in the string being asserted. To test alignment, inject the escapes into the fixture by hand, or assert on `visibleWidth` rather than `.length`.

Same family as a test that only passes valid input: it cannot fail in the way the code fails.

The acceptance path therefore needs a forced-color fixture or a real TTY smoke. Also assert that JSON and piped output contain no ANSI, `NO_COLOR` preserves the words while removing styling, and the banner writes only to stderr.

Progress has the same trap. A spinner driven only by time can look active while reporting nothing about completion. When bytes, rows, files, or jobs are measurable, render progress from the real completed amount.

## The check this file adds

The skill's Phase 6 says to run the command and read the output. That criterion caught real defects, and it is not sufficient on its own, because "the output is correct" and "the output is readable" are different questions.

**Read the human output as someone who does not know the domain.** What does the biggest number mean? What is the first thing the eye lands on? Is there a column where every row says the same thing? Those questions have answers a typecheck cannot produce.
