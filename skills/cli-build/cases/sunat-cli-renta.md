---
cli: sunat-cli (renta namespace)
target: Peru's tax authority annual income-tax return for individuals (F709), on a login-walled portal
origin: discovered
terrain: B
built: 2026-08-21
status: internal
distribution: npm
---

# sunat-cli — renta namespace

## What it does

Read-only consultation of the annual income-tax return for individuals: form
metadata, the 88-field schema, the prefilled declaration, filing history, and
proof of filing. Eight commands added to an existing 12-command CLI.

It cannot file, amend or pay, by design.

## Contract origin

Discovered. Recon ran first and produced `recon/sunat-f709-erenta-api.md`; this
build started from it rather than from the portal.

The initial classification was right (Terrain B, private API behind a SPA) but
the *portal* classification inherited from an older recon was wrong in a way
that would have cost a day. A note in the repo said the form lived at one host
with one auth mechanism. It turned out to be a different host, a different OAuth
client, and a different token audience from its sibling form, sharing only the
house style. **A token cached for the sibling form returns 401 here.** That is
the single most load-bearing fact in the build and it is invisible without
decoding both tokens and comparing the `aud` claim.

Recon paying off concretely: three gotchas were already measured before any code
existed, and each would otherwise have been debugged as a mystery.

- A client-version header is mandatory. Without it, every data endpoint returns
  422 with a message telling a *human* to update their browser. Four plausible
  header names were tried during recon and only one works, so guessing was not
  going to land it.
- One endpoint wants its form code without a leading zero while every one of its
  neighbours wants it with. Isolated by contrast: three variants tried, one
  returns 200, two return 422.
- The annual period uses a month sentinel of 13. Getting it wrong returns
  another period's data rather than an error, which is the worst failure shape:
  silent and plausible.

## Distribution choice

npm, inherited: the namespace was added to a published package rather than
started fresh, so the target was already decided.

Worth recording as a **finding against the skill's Phase 1**, because the
inherited choice is defective and the skill predicts exactly this defect. The
package's bin entry has a runtime-specific shebang, so an installer without that
runtime gets `env: <runtime>: No such file or directory` — a message naming
neither cause nor fix, which reads as "broken package" rather than "missing
prerequisite". The skill says three of four published packages in its corpus do
this. This is a fifth instance, and I did not fix it: correcting it means
changing the build target of the whole package, which is a different piece of
work than adding a namespace. It is logged rather than silently inherited.

## Blocks adopted

Cligentic was **not installed**, and the reason matters more than the decision.

The package already publishes an output contract (`src/utils/output.ts`)
consumed by 12 existing commands. The skill is explicit that a published
contract outranks a shared block, so adopting a block whose shape differs would
have meant either breaking 12 commands or maintaining two output paths. The
patterns were reimplemented inside the existing module instead, preserving every
existing signature.

| Pattern | Decision | Reason |
|---|---|---|
| `visibleWidth` / `padVisible` | reimplemented | Needed for column math; the existing table used `.length`, which over-pads styled cells by the size of the escapes |
| Semantic 256-colour palette | reimplemented | `danger` reserved for errors only |
| Single `shouldColor()` consult | reimplemented | Styling checked per call site leaks into pipes |
| `banner` | rejected | The CLI has no interactive entry point worth announcing; a banner on every invocation is noise for a tool agents call |
| Trust ladder, intent tokens, dry-run | rejected | Phase 4 exit: every command is a GET against the caller's own data. Nothing to gate. Adopting the ladder here would be a tax on every invocation that trains the human to approve without reading |
| Audit log | rejected | Same reason. The package has one for its write commands; reads do not earn an entry |

Recording the Phase 4 exit explicitly, rather than silently skipping it, is what
stops the next reader from reading its absence as an oversight.

## What broke

**A test failed and the code was right.** The table-alignment test trimmed
trailing whitespace before comparing row widths, which erases the very padding
under test. Every row did measure the same width. The test was wrong; the fix
was to compare the padded lines as-is and additionally assert the styled cell
really carried escapes, so the test cannot pass trivially.

**An export was imported from the wrong module.** `getCredentials` was imported
by analogy from the auth module; it lives in the config module. The typecheck
caught it, not me. Recurring lesson: grep the export before importing it, even
when the module "obviously" should have it.

**A defect found by running, not reading.** An unknown identifier returns
HTTP 202 with an empty body rather than a 404. The generic "non-JSON response"
error helped nobody; it is now a distinct code with a hint pointing at the
command that lists valid identifiers. This only surfaced from deliberately
passing a made-up id to the real service.

**Noise misread as a defect, then resolved by contrast.** With `FORCE_COLOR=1`
the runtime wraps everything written to stderr in a red escape the code does not
emit, so a carefully chosen error colour appeared to have a stray red prefix.
Running the same command without that variable showed clean output, which
identified it as runtime behaviour rather than a bug to chase.

## What this skill got wrong, or under-specified

**The colour-path warning is right and still insufficient as written.**
`human-output.md` says a test suite never exercises the colour path because
there is no TTY. True, and the consequence is sharper than stated: a test that
merely forces colour on can *still* pass trivially if the fixture happens to
carry no escapes. The defence that actually holds is two assertions — the
alignment property, plus a check that the styled cell's `.length` exceeds its
`visibleWidth`, proving escapes were present. Without the second, the test is
green and blind. Suggest the reference state both.

**Phase 6's "link it globally first" earned its place.** Verification through
the linked binary exercised the bin entry, shebang and resolved dependencies,
none of which a source-file invocation touches. It also surfaced that a full
test run had been failing purely from uninstalled dependencies — the 8 failures
were not code defects, and attributing them to the change would have been wrong.

## What I would do differently

Write the alignment test before the alignment code. It was written after,
which is why the first version encoded my assumption about the output rather
than the property being claimed.

Check the sibling form's token audience at the start rather than at the point of
building the session module. That single comparison invalidated an inherited
assumption, and it costs one decode.

## Evidence

- Repo: `crafter-research/sunat-cli`, package `@crafter/sunat-cli` (npm), v0.6.1 at time of build
- New source: `src/renta/{session,f709-api,login}.ts`, `src/commands/renta/index.ts`, `src/utils/style.ts`
- Machine contract: `src/schemas/renta.json`, reachable at runtime via `sunat-cli schema renta`
- Agent manual: `skills/sunat-cli/SKILL.md`, F709 section
- Tests: 346 pass, 0 fail across 32 files; 8 new in `tests/unit/renta.test.ts`
- Recon report and friction log: `recon/sunat-f709-erenta-api.md`, `recon/friction.md`
- Limitations, including the deliberate non-implementation of filing: `LIMITATIONS.md`
- Verified against the production service through the globally linked binary,
  browser closed after login; control request without the bearer token returns 401
