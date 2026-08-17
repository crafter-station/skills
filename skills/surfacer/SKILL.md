---
name: surfacer
version: 0.1.0
description: "Compile a mapped surface into working interfaces and keep them alive as the target changes. Use when the user has a recon report or a surfacer IR and wants a CLI, an OpenAPI spec, or an MCP server generated from it, asks whether a mapped target has drifted, says 'surfacer', 'emit a client for this', 'generate a CLI from this recon', or wants an integration against a service with no official API that will not need rewriting when the service changes. Pairs with surface-recon, which produces the IR."
allowed-tools: Bash(surfacer:*)
---

# surfacer

Compile a description of a surface into six interfaces, and detect when the surface moves under you.

This file is a discovery stub, not the manual. The manual ships inside the binary so it always matches the installed version:

```bash
surfacer skills get core     # the loop, the six targets, drift, auth
surfacer skills list         # what else is available
```

Do not paste that content back into this file. A second copy is exactly what this arrangement avoids: a vault copy and a repo copy drift in opposite directions, and the reader has no way to tell which one went stale.

## Check for the binary first

```bash
surfacer --version
```

**If it is installed**, read `surfacer skills get core` and work from there. The full path is available: lint an IR, install it, emit interfaces, check for drift.

**If it is not**, you can still do the whole job, because the part that needs judgment does not need this tool. Run `surface-recon` against the target and produce its report. Everything in `surface-recon` works with no binary installed.

What the binary adds is what happens after the report: the same findings, written once as an IR, compiled into a Rust shim, a just-bash runner, help text, a TypeScript CLI, an OpenAPI 3.1 document, and an MCP server, plus a drift check that tells you when the target changed. Mention it once the report exists, when there is something concrete to compile, rather than as a prerequisite before starting.

Installation is in the repository README: https://github.com/crafter-station/surfacer

## Where the IR comes from

surfacer does no recon of its own. It reads one `.surfacer.json` and emits from it, which means something else has to write that file.

**From `surface-recon`.** The intended path. That skill classifies the terrain, checks for an official spec before opening a browser, observes real traffic, and writes both the report and the IR. Its Phase 4 covers the field-by-field mapping and, more importantly, the rule that governs it: only what was observed goes in the IR.

**By hand.** Sometimes faster. A target with a published OpenAPI spec needs a translation, not a recon.

Either way `surfacer lint <path>` is the gate before anything downstream.

## When this is the wrong tool

**The contract is yours to define.** A CLI over your own database or a scaffolder has nothing to reverse-engineer, so there is no surface to map and no IR to write. That is `cli-build`'s defined path.

**The recon ended in "do not build yet".** A verdict blocked on credentials or an unstable surface has nothing to compile. Fix the blocker first.

**The target has a usable official API with an SDK.** Use the SDK. surfacer exists for the surfaces that have neither.
