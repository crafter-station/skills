# Friction log

A recon that ends at the verdict throws away half of what it produced. The report says what the target exposes. What it does not say is where **this skill** slowed you down, and that is the only input that improves the playbooks.

Two kinds of friction, logged differently.

## Profile friction: the playbook was wrong or thin

The highest-value kind. A terrain playbook claims a technique works and the target proves otherwise, or the target does something no playbook mentions.

Append to `recon/friction.md` next to the report, one line, at the moment it happens. Tag the affected plane and access mode:

```markdown
- [plane network][access granted] the session token rotates on every response, not just on login. Playbook says re-extract after auth; it needs re-extraction per request.
- [plane interactive][access owned] Screen Studio showed the edit as saved, but the project artifact did not change until export. State transition and round trip need separate receipts.
- [plane device][access owned] the camera BLE service disappeared after Wi-Fi activation. Identity must be re-enumerated after transport changes.
- [plane firmware][access owned] the outer update package unpacked, but every partition image remained signed. Static discovery must stop before patching.
```

The format that makes these usable later: **which plane, which access mode, what the playbook said, what actually happened.** Legacy reports may retain `[terrain B]`, but new reports use the profile tags.

## Tool friction: the command failed or misled

A command that errored for a reason its help text did not predict, an undocumented flag requirement, output that looked like success and was not.

Same file, tagged by tool:

```markdown
- [agent-browser] `react tree` fails with "DevTools hook not installed" unless `--enable react-devtools` is passed at launch. Not in `--help react`.
- [agent-browser] a route left active across a login produced a session that looked valid and was not.
```

**These have somewhere to go.** If the tool ships a feedback channel, use it, because a maintainer who never hears about friction cannot fix it:

```bash
agent-browser feedback "react tree needs --enable react-devtools at launch; --help react does not say so"
```

Check whether the channel exists before assuming it does. Absent one, the log entry is still worth writing: it is what you cite when you open an issue.

## Verdict friction: the gate did or did not hold

The gates exist to stop a confident wrong report. Whether they worked is worth recording either way.

```markdown
- [gate] the credentials gate stopped this recon at Phase 0. Correct call: no account, output would have been an inventory.
- [gate] captured the institutional domain before noticing the service runs on a subdomain. The gate names this exact mistake and I still made it. The check needs to fire earlier, in Phase 2 rather than at review.
```

A gate that fired and saved time is evidence it earns its place. A gate that existed and did not catch the thing it names is a defect in its wording, not in the reader.

## What happens to the log

The report ships to whoever asked for it. The friction log goes to whoever maintains the skill.

- **Profile friction** becomes a playbook edit, and the entry is the evidence for it.
- **Tool friction** becomes an upstream report, or a caveat in [agent-browser-recon.md](agent-browser-recon.md) when the behavior is real and unlikely to change.
- **Verdict friction** becomes a sharper gate in [gates.md](gates.md), or a gate moved earlier in the flow.

A log nobody reads is sediment. Consuming it is what makes writing it worthwhile, so hand it over with the report rather than leaving it in a directory.

## Write it during, not after

The details that improve a playbook are the ones you forget within the hour: the exact error text, the flag that was missing, the order you tried things in. A friction log written after the report is a reconstruction, and reconstructions lose precisely the specifics that would have been useful.
