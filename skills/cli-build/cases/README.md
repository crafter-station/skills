# Cases

One file per CLI built. This is the mechanism that makes the skill improve instead of being rewritten from memory every six months.

A case records what happened. It does not become a convention merely by existing; a finding earns its way into `conventions.md` by appearing in two or more independent builds.

## Why this exists

The skill this one replaces carried around forty lessons in prose, written once by looking backwards across four CLIs. They were genuinely valuable and they were also stale: when checked against the actual code, seven claims were wrong. One said a CLI had shipped without tests when it had grown to twenty-seven test files. One described a layering pattern attributed to a CLI whose real directory structure was flat. One recommended a flag that had since become a deprecated no-op.

Prose written from memory decays and cannot tell you it has decayed. A case written at build time, citing paths, can be re-verified.

## Writing a case

Create `cases/{cli-name}.md` when a build ends: shipped, abandoned, or paused. Abandoned builds are often the most informative.

```markdown
---
cli: {name}
target: {what it wraps}
terrain: {A-G, from surface-recon}
built: {date}
status: {shipped|internal|abandoned}
distribution: {source|npm|native|none}
---

# {name}

## What it does
{One or two sentences.}

## Recon
{Link to the recon report. What the terrain turned out to be, and
whether the initial classification was right.}

## Distribution choice
{Which target, and why. What the audience actually was.}

## Blocks adopted
{Which shared blocks were taken wholesale, which were hybrids, which
were rejected: each with a reason. A rejection with a stated reason is
worth more than an adoption without one.}

## What broke
{Anything that failed after it was declared done. Include the fix.}

## What I would do differently
{The honest version.}

## Evidence
{Repo path, published package name, test count, where the audit log lands.}
```

## Who may be named

Three boundaries, and they are not symmetric.

**Your own code: name it, defects included.** A case about a CLI you wrote can be specific about what broke, because it is yours to disclose. That specificity is most of the value.

**Someone else's code: describe the defect, not the repository.** A published package with a dead `--dry-run` flag teaches the same lesson without the name. The subject carries no pedagogical weight, and pairing a defect with a subject turns a lesson into an accusation. Anonymizing a public package is also thinner than it looks, which is a reason to drop the subject rather than to disguise it.

**Third-party targets: by class, never by identity.** Recon turns up real bugs in systems nobody asked you to audit: a portal that returns 200 with a wrong password, a deep link that redirects to a dead domain, a widget whose layout a captcha bypass depends on. Write "a university portal returned 200 with incorrect credentials". Never write which one. This is stricter than the rule for other people's open source, deliberately: an npm package was published for others to use, an internal government portal was not.

Aggregate findings across many targets belong in [portfolio-shape.md](portfolio-shape.md), which counts rather than lists.

## Rules

**Cite paths, not impressions.** "Layering is clean" is unverifiable. `src/commands/` plus a flat `src/lib/` is a fact someone can check. In a case about your own code, cite real paths. In a case about anyone else's, cite the shape.

**Record the rejections.** The most useful entry in a corpus case was a table of seven shared blocks *not* adopted, with reasons. It prevented the next person from "fixing" a deliberate divergence back into a conflict.

**Write it when it is fresh.** A case written three months later is a reconstruction. The details that save time are the ones you forget first.

**Contradict the skill when the code contradicts it.** If a reference file says one thing and your build found another, the case says so. That contradiction is the input that keeps the references honest; and it is exactly how the seven stale claims in the predecessor skill were caught.

## Distilling into conventions

A finding becomes a convention when it appears in two or more independent builds: meaning no shared code between them. That convergence is the signal. Independent arrival at the same design is evidence; one team's preference is not.

When promoting a finding to `conventions.md`, cite the cases it came from. A convention with no case behind it is exactly the kind of remembered-not-verified claim this structure exists to prevent.
