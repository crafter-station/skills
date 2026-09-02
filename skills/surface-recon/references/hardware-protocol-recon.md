# Connected-device protocol recon

Use this for Terrain H targets that expose USB, BLE, serial, Wi-Fi, storage, an accessory bus, or a firmware-update channel. The target is not one protocol. It is a set of planes whose availability and meaning change with physical topology and device state.

## 1. Decompose the surface

Map each plane independently before composing them:

| Plane | Typical evidence |
| --- | --- |
| Power and boot | charge state, boot mode, recovery mode, reset behavior |
| Discovery and identity | USB descriptors, BLE advertisements, mDNS, serial banners |
| Control | GATT writes, USB control or bulk transfers, serial commands, RPC |
| Data | streams, notifications, sockets, bulk endpoints |
| Storage | mounted volumes, MTP, block devices, media catalogs |
| Update | firmware packages, bootloader, signatures, rollback rules |
| Accessory | dock, cable, adapter, external storage, companion device |
| Control underlay | SSH, Tailscale, Ethernet, Wi-Fi, local UI, recovery path |

Do not transfer a result between planes. A command accepted over serial is not proven over BLE. A parser found in a client is not proof that the current model, firmware, mode, and transport support it.

## 2. Record the full context

Every finding must carry enough context to reproduce it:

- device model and hardware revision
- firmware version, or `unknown` with the exact confirming step
- host hardware, OS, driver, runtime, and tool versions
- transport and physical topology, including dock, cable, hub, and adapter
- device mode, power state, lock state, activation state, storage selection, and pairing state
- direction, target, characteristic or endpoint, framing, and timing
- launch surface and authorization context, such as SSH daemon, terminal app, signed app, or GUI session

Treat this as a matrix. The same device in USB storage mode, BLE application mode, recovery mode, or behind a dock can expose different contracts.

## 3. Use a mutation ladder

Advance one rung at a time:

1. Passive observation: descriptors, advertisements, filesystem inventory, packet capture.
2. Ephemeral connection: service or endpoint discovery, then disconnect.
3. Read-only request: a source-backed query whose response semantics are known.
4. Persistent authentication: pairing, trust records, keys, or device registration.
5. State transition: wake, mode switch, start stream, mount, or enable network.
6. Data mutation: setting change, upload, delete, calibration, or write.
7. Firmware mutation: update, rollback, bootloader unlock, patch, or flash.

State the current rung and obtain explicit approval before the first persistent or state-changing action. Pairing is a mutation even if every later command is read-only.

## 4. Capture before interaction

- Enable receive paths before authentication or pairing. Devices can emit useful state during setup.
- Record the official client or a hardware-verified implementation before guessing frames.
- Pace write-without-response traffic against the transport's readiness signal.
- ACK device requests when the observed protocol requires it. Record an ACK as receipt, not proof that state changed.
- For persistent pairing, generate one per-install identity and keep it outside version control.
- Log each outbound frame with transport, direction, target, command, payload length, and source of truth.
- Verify a claimed state change through a returned state and, when possible, an independent surface.
- Treat plane composition as an experiment. Mounted USB storage can suppress a radio AP, and a radio transition can remove the controller used to observe it.

## 5. Build a defensive parser

- Enforce minimum and maximum frame lengths before allocation or indexing.
- Validate framing and checksums before interpreting payloads.
- Handle fragmented frames, coalesced frames, garbage prefixes, and partial tails.
- Do not assume a sliced byte buffer starts at numeric index zero. Normalize it or index relative to its real start.
- Keep unknown commands and payloads as opaque evidence until their meaning is independently confirmed.
- Do not assume one logical value is one wire field. A path can be extensionless in one TLV while its filename and extension live in another. Decode tag, length, subtype, and record boundaries before applying content rules.
- Validate a structured decode against both its internal invariants, such as declared record count, and an independent plane, such as USB inventory or a device UI. Matching both is stronger than a plausible string scrape.
- Keep HTTP method, query serialization, resource identity, device-busy state, and transport separate. A failed HEAD does not reject GET, and percent-encoded query data is not necessarily equivalent to the raw form sent by the measured client.
- Do not let one failed diagnostic method suppress another independently authorized probe. Return a nonzero process status when every acceptance path failed, even if every tool invocation itself completed.
- Whenever possible, exercise a negative control and positive control in the same device-state window. One storage selector returning not-found while another serves the same measured path establishes the mapping more strongly than an isolated success.
- Do not use response-body length as an HTTP success signal. Error responses can carry bodies. Require status, method-specific semantics such as `206`, requested byte count, and retention outcome separately.
- Run parser self-tests and at least one compiled live probe. Compilation does not expose runtime indexing failures.

## 6. Preserve useful evidence without leaking it

Log the first frame of each type, semantic state changes, errors, and a final count by type. High-frequency binary traffic should not produce one line per notification.

Never use an ordinary hash as redaction for a short or guessable value. It can be brute-forced and remains correlatable. Use an opaque per-session variant such as `v1`, or a keyed digest whose key is not retained. Never persist raw pairing identities, device identifiers, tokens, SSIDs, passphrases, media names, or personal telemetry unless the user explicitly needs them.

Keep the raw secret-bearing capture outside version control. The durable receipt should contain sanitized commands, counts, timing, state transitions, tool versions, and failure causes.

For multi-phase binary sessions, preserve a private machine-readable trace even when the run fails before the requested result. Prefix each raw packet with a stable phase identifier and explicit length so offline analysis can separate authentication, registration, state transition, query, and cleanup without replaying the device. Document the phase map in the sanitized receipt, but keep packet bodies private.

## 7. Interpret state conservatively

Keep these distinct:

- zero
- null or absent field
- silence or timeout
- explicit error or rejection
- transport connection or completed write
- application authentication or session registration
- acknowledged receipt
- independently verified state change

A zero storage field does not mean no storage. A connected socket or completed write does not prove that the peer authorized the application session. A response does not mean a supported command. An ACK does not prove the requested state. Correlate surprising values with another plane before assigning semantics.

## 8. Report the contract

Terrain H connected-device reports should include:

1. Interface and context matrix.
2. Mutation ledger with approval and persistence.
3. Command matrix marked `measured`, `rejected`, `cited`, or `inferred`.
4. Telemetry census with rates and semantic changes.
5. Secret-handling and evidence-retention boundary.
6. Crash and tool-friction log.
7. Unknowns with the exact confirming experiment.
8. Next safe rung on the mutation ladder.

## 9. Compile only the overlap into an interface

A generated CLI, API, SDK, or MCP needs two compatible contracts:

- the measured protocol contract: what the target accepted, returned, and independently confirmed
- the operator contract: physical prerequisites, consent, consequence, privacy, cleanup, and recovery

Expose an operation only where both contracts overlap. A source-derived resource suffix, correlated proxy name, or plausible command can remain in the report with `inferred` provenance, but must not silently become a stable interface operation.

When device responses contain private resource names or paths, keep them in private in-process records and expose opaque IDs scoped to the current capture. Do not claim those IDs are stable after a refresh. If an existing measured probe requires a private path, bridge it through a mode-`600` ephemeral file or private stdin, never through process argv or default stdout, and remove it on every exit path.

Machine output should carry a schema version, command identity, result, provenance, and recovery steps. Consequence gates must be explicit flags that fail before protocol traffic. Keep separate gates for physical link confirmation, persistent authentication, state transition, data mutation, firmware mutation, and bounded data reads.

Preserve the plane matrix in the generated interface. Human help and machine schema should identify whether each operation is offline, wired USB storage, a mapped or unmapped USB interface, BLE, device Wi-Fi, serial, or control underlay. Do not label SSH, Tailscale, or a second executor as a device protocol, and do not collapse BLE and Wi-Fi into a generic wireless capability.

Before calling the interface usable, test:

- offline decode against internal count invariants and an independent plane
- default output for secret, filename, and path leakage
- missing-consent and wrong-link refusal before target traffic
- cleanup of ephemeral private inputs on success, failure, and timeout
- one positive and one negative physical control for every exposed selector or storage mapping
- the exact globally linked binary, not only source-level tests

## 10. Design experiments that can lose their controller

If the experiment changes the network, radio, USB mode, or power plane carrying the control session, assume the controller will disappear.

Before the transition:

- stage the exact probe, private inputs, and dependencies on the target host
- capture the original recoverable state without logging its secrets
- use a one-shot local runner with a strict timeout, cleanup trap, private PID guard, and durable receipt
- keep operator link confirmation and mutation approval as separate gates; seeing the correct network does not authorize a state-changing command
- prove that the cleanup restores the control network, remounts storage, and clears temporary clipboard data
- avoid supervisors whose default restart behavior has not been measured
- validate the runner in refusal mode before the physical run: missing consent, wrong link, conflicting transport, and duplicate-process cases should exit before protocol traffic
- in recovery-critical shell runners, avoid runtime-reserved variable names and prefer absolute paths for system tools so an environment mutation cannot disable cleanup

During and after the transition:

- distinguish API acceptance, observed target identity, assigned address, target-peer reachability, and service reachability
- do not identify a device from a private address or ICMP reply alone; an ordinary LAN can use the same gateway address. Require an overlapping link identity such as SSID/BSSID or USB path plus a target-specific protocol signature
- treat a control-channel drop as route-transition evidence, not target-association proof
- require the target identity and target-peer receipt to overlap in time
- record whether the process ran through SSH, a terminal, an app bundle, or a GUI because macOS privacy permissions can differ between them
- preserve failures from both the controller and the isolated executor
- pair every temporary state-entry command with a bounded exit path, and attempt the exit before parsing, persistence, or optional follow-up work

When the documented command and current implementation disagree, inspect the live execution path before replay. A parser, constant, stale protocol map, or fallback branch is not evidence that the active product flow sends that command.

Stop when the next useful step crosses an unapproved rung, requires guessing a mutating command, or risks making the device unrecoverable.
