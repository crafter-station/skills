# Terrain practice backlog

Practice targets should be owned, public, disposable, or explicitly granted. Each exercise ends in a report and friction log, not an implementation.

| Order | Terrain | Acceptance boundary | Instrument | Safe practice target | Required artifact | Safety gate |
|---:|---|---|---|---|---|---|
| 1 | Command: CLI | Contract conformance | `--help`, JSON/schema output, exit codes, disposable state | A locally installed open-source CLI | Command tree, success/error fixtures, state diff | Use a temp config and no external writes |
| 2 | Command: MCP | Tool/resource enumeration plus controlled call | `tools/list`, `resources/list`, JSON-RPC capture | A local filesystem or demo MCP server | Tool catalog, schemas, call receipts | Disposable directory, mutations disabled first |
| 3 | Artifact: export or project package | Parse and semantic round-trip | Real disposable sample, metadata tools, schema diff | A new Screen Studio test project or public export format | Corpus, schema, version drift, round-trip receipt | Never inspect unrelated personal projects |
| 4 | Interactive: desktop app | Action to settled UI/artifact state | Screenshot, accessibility, shortcuts, app logs | Screen Studio with a disposable project | Workflow map, automation seams, output correlation | No app patching or licensing bypass |
| 5 | Network: public or owned mobile app | Independent replay of owned read flow | Emulator/device, proxy, UI correlation | A demo or owned non-financial app | Sanitized request catalog and auth lifecycle | No pinning bypass unless explicitly authorized and legally appropriate |
| 6 | Device: BLE | Receipt plus coherent post-state | OS GATT enumeration, passive notifications, differential action | Owned dev board or camera | Service map, characteristic roles, state corpus | Pairing and every mutation require separate approval |
| 7 | Device: USB/HID | Enumeration, passive capture, bounded replay | USB descriptors, system registry, passive capture | Owned microcontroller or camera | Interface/endpoints map and transfer corpus | No blind vendor writes or fuzzing |
| 8 | Device: serial | Framed replay and state verification | Logic analyzer or serial capture, known baud settings | Owned Arduino or development board | Framing, checksum, request/reply fixtures | Current limiting and recovery path |
| 9 | Firmware: offline update package | Image and trust-chain inventory | Vendor package, hashes, extractors, strings | Public firmware update for owned hardware | Partition map, signatures, compression/encryption findings | Offline only, no flashing in first pass |
| 10 | Runtime: accelerator | Accepted workload plus execution placement | Compiler/runtime logs, traces, per-unit metrics | Local GPU, NPU, or sandbox | Constraint catalog and same-machine baseline | Read-only workload and thermal limits |
| 11 | Composite: camera system | Cross-plane identity and receipts without evidence leakage | BLE, Wi-Fi, USB, artifact correlation | Owned Osmo Nano | Plane matrix, provenance graph, mutation audit | Evidence never transfers across planes automatically |
| 12 | Composite: capture workflow | Two artifacts synchronized with provenance | Screen Studio export plus camera media | Disposable Screen Studio plus Nano recording | Source hashes, offset, drift, and handoff manifest | Ask before recording and importing personal media |

## Progression

1. Start with command and artifact terrains because their acceptance proofs are deterministic and consequences stay local.
2. Move to interactive and network terrains where identity, auth, and UI state must be correlated.
3. Practice BLE, USB, and serial on owned development hardware before vendor-specific consumer devices.
4. Treat firmware as offline archaeology until a verified recovery path exists.
5. Attempt composite systems last. Their main difficulty is provenance across planes, not packet decoding.

## Selecting the next exercise

Choose the smallest exercise that adds one new observation instrument or proof type. Record:

- terrain profile;
- practice target;
- instrument;
- acceptance proof;
- maximum consequence;
- expected report artifact;
- stop condition.

Do not choose a target because it sounds exotic. Choose it because it teaches one reusable technique the current playbooks lack.
