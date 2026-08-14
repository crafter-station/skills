---
cli: osmo
target: removable action-camera storage on macOS
origin: discovered
terrain: H with a Terrain F file surface
built: 2026-08-14
status: internal
distribution: npm
---

# osmo

## What it does

Discovers a mounted camera, inventories and probes its media, imports originals through verified partial copies, records two-phase receipts, and safely ejects the volume. It deliberately does not control camera settings or delete source media.

## Contract origin

The physical device was Terrain H and its mounted ExFAT file surface was Terrain F. Documentation confirmed file transfer through the camera's media directory. No supported camera-control contract was found, so the CLI stops honestly at the filesystem boundary.

## Distribution choice

The CLI is bundled to a Node target and packaged with a Node shebang. Bun remains the package manager, build tool, and test runner. This keeps local linking fast while allowing an installed tarball to run anywhere Node 20 or later is available.

## Blocks adopted

| Block | Verdict | Reason |
|---|---|---|
| `xdg-paths` | hybrid | An app-specific home override plus native state roots cover this config-free tool. |
| `audit-log` | hybrid | Import and eject use two-phase day-bucketed JSONL receipts. |
| `atomic-write` | hybrid | Media copies use an exclusive partial sibling, SHA-256 verification, and rename. |
| `doctor` | hybrid | Checks are device-specific and the media probe is optional. |
| `json-mode` | rejected | The CLI publishes one versioned envelope rather than bare values. |
| `next-steps` | hybrid | Next actions live in envelope metadata, keeping machine stdout to one object. |
| `trust-ladder` | rejected | Import never changes source media and eject is explicit. Dry-run, collision blocking, hashes, and receipts are proportional safeguards. |
| `detect` | hybrid | Central TTY and color detection includes explicit human-mode precedence. |
| `banner` | adopted in 0.2 | The gradient wordmark writes only to stderr and keeps machine stdout untouched. |
| `style` | adopted in 0.2 | Semantic color and ANSI-safe width helpers back the human surface. |

## What broke

The first real inventory counted host-created AppleDouble sidecars as videos because they shared the media extension. The latest-file command selected one and the probe failed. Discovery now excludes dotfiles before classifying extensions, and a regression fixture preserves the failure.

The first release also passed its agent, safety, packaging, and live-device checks while remaining visually unfinished. `banner` and `style` had been rejected because the command surface was small. Version 0.2 added a TTY-only banner, semantic colors, bold hierarchy, ANSI-safe tables, a storage bar, readable metadata, and real byte-level copy progress. Machine JSON remained free of ANSI.

## What I would do differently

Seed file-format fixtures with platform metadata sidecars before the first live run. Run the packed install immediately after the first successful build because skill-path resolution is independent from checkout behavior. Unless the user explicitly asks for MVP, minimal, or headless output, adopt the human-output blocks before calling the first release complete.

## Evidence

- 15 tests cover forced color, `NO_COLOR`, ANSI-safe width, JSON cleanliness, and progress events.
- Three real media files were copied from the mounted device with byte progress, SHA-256 verification, and two-phase receipts.
- A dry-run resolved the real device without ejecting it.
- An isolated tarball install served both the bundled skill and runtime schema.
- The globally linked command reported version `0.2.0`.

## Folded friction

- A shared JSON block's bare-value shape can conflict with a versioned envelope, so retain the detection convention while protecting the published contract.
- USB mass storage is reliable for files and ejection but cannot support honest camera-control commands.
- Live storage directories can contain host-created sidecars that look like media by extension.
- A CLI can pass every agent and safety gate while still feeling unfinished to a human. Full human output should be the default unless reduced scope is explicit.
