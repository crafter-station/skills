# Recon report template

Copy this, fill it, and delete sections that do not apply. Keep every frontmatter field so reports remain queryable.

```markdown
---
type: surface-recon
target: {url, package, binary, device, or name}
created: {date}
access: {public|owned|granted|blocked|mixed}
planes: [{network|interactive|command|artifact|device|firmware|runtime}]
primary-plane: {one plane}
acceptance: [{enumeration|replay|state-transition|contract-conformance|round-trip|receipt-plus-poststate|execution-placement|boot-and-recovery}]
maximum-consequence: {passive|reversible|creative|persistent|destructive|external}
legacy-terrain: {A-H|none}
auth: {none|api-key|oauth2|browser-bootstrapped-token|cookie|jwt|hmac|certificate|device-pairing|owned-device|mixed}
official-surface: {complete|partial|none}
confidence: {high|medium|low}
---

# {Target}, Recon

## Verdict
{Build it, build it narrowly, or do not build yet. Name the load-bearing reason.}

## What it is
{What the target does, who uses it, and which boundary is being reconstructed.}

## Recon profile

| Dimension | Selection | Why |
|---|---|---|
| Access | owned | Operator controls target and account |
| Planes | device, network, artifact | BLE bootstrap, Wi-Fi control, media files |
| Acceptance | receipt-plus-poststate, round-trip | Writes need receipts; media must reopen |
| Maximum consequence | persistent | Settings can survive reboot |

## Plane map

| Plane | Surface | Instrument | Authorized consequence | Acceptance proof |
|---|---|---|---|---|
| device | BLE GATT | scanner and official-client capture | reversible | receipt plus poststate |
| artifact | project package | structural diff and producer reopen | creative | round trip |

## Official surface
{Specs, SDKs, schemas, manuals, or none found. Separate cited behavior from observation.}

## Authentication and authority
{Exact auth flow, target ownership, granted scope, physical-presence requirements, token rotation, and what is explicitly out of scope.}

If the recon also emits a Surfacer IR, map auth to the IR modes defined in `ir-target.md`. The report can describe auth schemes the IR cannot carry.

## Evidence ledger

| Plane | Claim | Provenance | Acceptance proof | Receipt |
|---|---|---|---|---|
| network | GET /v1/items lists media | observed | replay | capture.har plus replay transcript |
| device | command changes mode | observed | receipt-plus-poststate | frame capture plus status readback |
| firmware | inner image is signed | cited and observed | enumeration | vendor note plus package hash |

Provenance is `observed`, `cited`, or `inferred`. Inferred claims always belong under Needs verification until their acceptance proof succeeds.

## Network contract

| Method | Path | Purpose | Auth | Provenance | Replay |
|---|---|---|---|---|---|
| GET | /api/v1/thing | List things | Bearer | observed | verified |

Only independently observed network rows can enter the Surfacer IR.

## Command contract

| Command, tool, or function | Input schema | Output and exit state | Poststate | Verified |
|---|---|---|---|---|

## Interactive state map

| Precondition | Action | Visible transition | Persisted poststate | Recovery |
|---|---|---|---|---|

## Artifact contract

| Artifact | Structure | Volatile fields | Controlled mutation | Round trip |
|---|---|---|---|---|

## Device protocol

| Transport | Identity | Operation | Receipt | Independent poststate | Verified |
|---|---|---|---|---|---|

Add the interface/context matrix, mutation ledger, command matrix, telemetry census, private evidence boundary, and next safe mutation rung required by `hardware-protocol-recon.md`.

## Firmware contract

| Package or partition | Hash | Signature or integrity | Version rule | Recovery evidence |
|---|---|---|---|---|

## Runtime constraints

| Workload | Accepted form | Placement receipt | Fallback behavior | Baseline |
|---|---|---|---|---|

## Blockers
{For each blocker: what was attempted, observed result, and exact unblocker.}

## Gotchas
{Specific details that save the next operator time.}

## Needs verification
{Every unresolved claim and the exact proof that would resolve it.}

## Safety and recovery
{Consequence ceiling, backups, rollback, recovery path, disposable fixtures, and stop conditions.}

## Evidence
{Paths and hashes for captures, transcripts, screenshots, schemas, artifacts, descriptors, packages, and receipts.}
```

## Profile variants

**Blocked access** sets `access: blocked`, usually `confidence: low`, and inventories only the public or operator-authorized surface. Name the exact unblocker. Do not treat lack of access as permission to bypass controls.

**Network-only** profiles can omit the command, artifact, device, firmware, and runtime sections.

**Interactive plus artifact** profiles need both a visible state transition and a producer reopen. Screen state alone does not prove persistence.

**Device** profiles require stable target identity, a transport or protocol receipt, and independent poststate verification. Follow [hardware-protocol-recon.md](hardware-protocol-recon.md).

**Firmware** profiles remain passive until a backup, recovery path, expendable target, and explicit authorization exist. Static package findings use enumeration, not boot-and-recovery.

**Runtime** profiles require placement evidence because successful output can hide fallback.
