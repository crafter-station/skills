# Terrain model

A terrain is not one technology label. Describe it as a profile with four dimensions:

```text
access + planes + acceptance proofs + maximum consequence
```

This prevents a web portal, desktop app, file format, and USB device from being forced into one flat list. A target can expose several planes at once, and evidence from one plane does not automatically prove another.

## 1. Access

| Value | Meaning | Recon posture |
|---|---|---|
| `public` | No identity or physical possession is required | Observe within public limits |
| `owned` | The user owns the account, app data, device, or artifact | Exercise authorized flows with explicit consequence gates |
| `granted` | A third party explicitly granted scoped access | Record scope and stay inside it |
| `blocked` | Required credentials, authority, entitlement, or physical access are absent | Inventory only, low confidence, state the unblocker |
| `mixed` | Different planes have different access states | Record access per plane |

Authentication is an implementation detail inside access. Keep exact auth mechanisms in the report, but do not use OAuth versus cookies as the terrain category.

## 2. Planes

| Plane | Includes | First useful instruments | Typical artifact |
|---|---|---|---|
| `network` | HTTP, GraphQL, WebSocket, gRPC, local sockets, Wi-Fi application protocols | Official specs, HAR, proxy, packet capture, independent replay | Request catalog and replay fixtures |
| `interactive` | Web UI, mobile UI, desktop UI, accessibility and gesture surfaces | Screenshot, accessibility tree, UI automation, state snapshots | Workflow and state-transition map |
| `command` | CLI, SDK, MCP, plugin, local daemon, tool protocol | `--help`, schema, tool/resource enumeration, exit codes, controlled calls | Command or tool contract |
| `artifact` | Files, exports, project packages, databases, media containers | Real samples, metadata tools, schema inference, round-trip tests | Versioned schema and corpus |
| `device` | USB, BLE, serial, HID, NFC, Wi-Fi Direct, vendor transports | OS enumeration, descriptors, passive capture, differential sessions | Transport map and packet/state corpus |
| `firmware` | Update packages, bootloaders, partitions, images, OTA flows | Official packages, hashes, extractors, strings, disassemblers | Image and trust-chain inventory |
| `runtime` | Compiler, driver, accelerator, sandbox, execution substrate | Accepted/rejected workloads, tracing, per-unit metrics | Constraint and placement catalog |

List every observed plane. Use `primary-plane` only to route the first playbook. Composite targets are normal:

```yaml
access: owned
planes: [device, network, artifact]
primary-plane: device
```

## 3. Acceptance proofs

Choose the proof before probing. A successful observation is not automatically a verified contract.

| Proof | What it establishes | Required receipt |
|---|---|---|
| `enumeration` | The surface exists on this version and host | Descriptor, schema, help, tool list, or inventory |
| `replay` | An observed read flow can run independently | Same semantic response outside the original client |
| `state-transition` | An interaction causes the expected state change | Before state, action, command-specific result, after state |
| `contract-conformance` | A command, SDK, or tool follows a stable input/output contract | Success, error, exit/status, and schema fixtures |
| `round-trip` | An artifact can be parsed and emitted without semantic loss | Source hash, normalized equivalence, and version record |
| `receipt-plus-poststate` | A device mutation was accepted and settled | Transport receipt, protocol receipt, and coherent post-state |
| `execution-placement` | Work ran on the intended runtime or unit | Per-unit trace or metric, not aggregate success |
| `boot-and-recovery` | A firmware change boots and has a recovery path | Verified image identity, boot evidence, rollback or restore evidence |

One plane can require multiple proofs. A device transport may need `enumeration` for descriptors, `replay` for a passive query, and `receipt-plus-poststate` for a mutation.

## 4. Maximum consequence

| Value | Examples | Gate |
|---|---|---|
| `passive` | Docs, descriptors, screenshots, reads, hashes | Authorization and privacy boundary |
| `reversible` | Temporary mode, mock, disposable project, session pairing | Cleanup and before/after evidence |
| `creative` | Recording, photo, export, test message, new local artifact | Ask before each media-creating or externally visible action |
| `persistent` | Settings, account state, BLE pairing, device writes | Explicit approval, audit before action, recovery plan |
| `destructive` | Delete, overwrite, format, firmware flash without safe rollback | Do not proceed without exact target, explicit approval, backup, recovery |
| `external` | Purchase, banking, public post, message to another person | Separate transactional authorization and final confirmation |

Set the maximum consequence authorized for the run. Discovery does not authorize mutation.

## Profile examples

### Screen recording application

```yaml
access: owned
planes: [interactive, artifact]
primary-plane: interactive
acceptance: [state-transition, round-trip]
maximum-consequence: reversible
```

### Owned camera with BLE, Wi-Fi, and USB storage

```yaml
access: owned
planes: [device, network, artifact]
primary-plane: device
acceptance: [enumeration, replay, receipt-plus-poststate, round-trip]
maximum-consequence: persistent
```

### MCP server

```yaml
access: owned
planes: [command, network]
primary-plane: command
acceptance: [enumeration, contract-conformance, state-transition]
maximum-consequence: reversible
```

### Neural accelerator

```yaml
access: owned
planes: [runtime]
primary-plane: runtime
acceptance: [contract-conformance, execution-placement]
maximum-consequence: passive
```

## Legacy A-H crosswalk

Existing reports remain valid. New reports use the profile above and may retain `legacy-terrain` for search compatibility.

| Legacy | New profile starting point |
|---|---|
| A | `public + network or command + replay or conformance` |
| B | `public or owned + network/interactive + replay` |
| C | `owned + network/interactive + replay/state-transition` |
| D | `blocked + network/interactive` |
| E | `public or owned + network/artifact + replay` |
| F | `owned or public + artifact + round-trip` |
| G | `owned + interactive/command/network/artifact` |
| H | Split into `device`, `firmware`, or `runtime`; do not keep them collapsed |
