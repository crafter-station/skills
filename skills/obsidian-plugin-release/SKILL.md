---
name: obsidian-plugin-release
version: 1.0.0
description: |
  Release a new version of an Obsidian community plugin without forgetting steps.
  Use when: (1) user says "release the plugin", "bump <plugin> to X.Y.Z", "ship a
  new Obsidian release", "tag a new plugin version", "publish to the obsidian
  directory", (2) the working directory contains manifest.json + main.js +
  versions.json (Obsidian plugin signature), (3) user wants to scaffold the
  release workflow into an existing plugin (`scaffold-workflow` arg).
  Handles version bump across manifest.json + package.json + versions.json,
  build, lint, conventional commit, signed annotated tag, push, and lets the
  GitHub Actions workflow publish the release with build-provenance attestation.
  Idempotent and dry-run-safe.
---

# obsidian-plugin-release

Releasing an Obsidian plugin has 12 manual steps that are easy to half-do (forget `versions.json`, push tag before main, sign assets without provenance). This skill collapses the flow into a single intent: pick a version → ship.

## Detection

The current directory is an Obsidian plugin if all of these exist at the root:

- `manifest.json` with `id`, `version`, `minAppVersion` keys
- `versions.json` (the map `pluginVersion → minAppVersion`)
- `main.js` listed in `.gitignore` is fine — we rebuild it

Refuse to run if any of those are missing. Suggest `scaffold-workflow` if `manifest.json` exists but `.github/workflows/release.yml` does not.

## Commands

### `release <version>` — full ship

```bash
bun run scripts/release.ts <version>          # via package.json script if user added it
# OR direct
~/.claude/skills/obsidian-plugin-release/scripts/release.ts <version>
```

Steps the script does (each one a hard gate — stop on failure):

1. **Verify clean tree** — abort if uncommitted changes (unless `--allow-dirty`).
2. **Verify version is new** — `versions.json` must not already contain it.
3. **Bump version atomically** — write the same `<version>` to `manifest.json`, `package.json`, and append `versions.json` keyed to current `minAppVersion`. Use `JSON.parse → mutate → write` (preserve trailing newline + tab indent that Obsidian expects).
4. **Build** — `bun run build`. Abort on non-zero.
5. **Lint** — `bunx eslint src/` (skip if user has no `src/` — JS-only plugins exist). Abort on errors.
6. **Stage** — `git add manifest.json package.json versions.json main.js styles.css`. Only those 5 files.
7. **Commit** — conventional message, no Co-Authored-By:
   ```
   chore: release <version>
   ```
8. **Push main** — `git push origin <current-branch>`.
9. **Tag** — `git tag -a <version> -m "Release <version>"` (annotated because `tag.gpgSign=true` is common; annotated works either way).
10. **Push tag** — `git push origin <version>`. This triggers the release workflow.
11. **Wait for workflow** — `gh run watch --exit-status` against the latest run on this tag. Abort if it fails.
12. **Verify release** — `gh release view <version> --json assets` must include `main.js`, `manifest.json`, `styles.css`. Attestation is verified via `gh attestation verify` on `main.js`.

Print the release URL + the community page (`https://community.obsidian.md/plugins/<id>`) + the deep link (`obsidian://show-plugin?id=<id>`) at the end.

### `release <version> --dry`

Print every file that would change, the commit message, the tag message, and the workflow that would fire. No writes, no network calls.

### `release --check`

Audit current state. Output:

- Last released version (from `versions.json`)
- Current `manifest.json` version (warn if ahead of `versions.json`)
- Git tree clean? Branch? Ahead/behind origin?
- Build passes locally?
- Lint passes locally?
- Workflow file present? Has attestation step?

Use this before running a release if anything feels off.

### `release scaffold-workflow`

Drop `.github/workflows/release.yml` into the current plugin. Idempotent — refuses to overwrite unless `--force`.

Template lives at [templates/release.yml](templates/release.yml). It:

- Triggers on `[0-9]+.[0-9]+.[0-9]+` semver tags
- Sets up Bun with frozen lockfile
- Builds via `bun run build`
- Generates a build-provenance attestation over `main.js`, `manifest.json`, `styles.css` using `actions/attest-build-provenance@v2`
- Creates or updates the release with the 3 signed assets
- Required permissions: `contents: write`, `id-token: write`, `attestations: write`

Also offer to scaffold [templates/eslint.config.mjs](templates/eslint.config.mjs) if the user is starting from scratch — it ships with the obsidianmd plugin pre-wired and the ignore globs (`web/**`, `assets/**`, `scripts/**`) that match the Obsidian scanner expectations.

## Edge cases

- **`tag.gpgSign=true`**: always use `git tag -a -m "..."` to avoid the "no tag message" error. Annotated tags work whether signing is enabled or not, so we use them unconditionally.
- **No `bun` available**: fall back to `npm run build` + `npx eslint src/`. The released workflow uses Bun regardless — local dev tool is incidental.
- **`web/` subdir present**: the scanner used to lint `web/**` and flag the Next.js landing site as a million unsafe-returns. Make sure `eslint.config.mjs` has `web/**` in `ignores` and the ignores block sits **before** `obsidianmd.configs.recommended` (the obsidianmd config spreads `files: ["**/*.ts", "**/*.tsx"]` which otherwise picks `web/` up). See [references/scanner-warnings.md](references/scanner-warnings.md).
- **Plugin not yet listed on Obsidian Community**: the workflow still runs. The release exists, the attestation exists, the deep link `obsidian://show-plugin?id=<id>` only works once Obsidian's directory crawler picks it up (≤24h after submission).
- **First release ever**: the script accepts `--first` and skips the "version is new" check. Useful when bumping from `0.0.0` to `0.1.0` for the first submission.

## Anti-patterns (don't)

- **Don't bypass the tag**. The workflow is the source of truth for attestation. Manual `gh release create` skips the OIDC signing step and the Obsidian scanner will flag missing provenance.
- **Don't squash `versions.json`**. It's a permanent ledger. Appending only.
- **Don't push tag before main**. Workflow checks out the tag commit; if main isn't there yet, the build references commits that don't exist on the default branch.
- **Don't release from a dirty tree**. The committed `main.js` must match the built `main.js` from the source. If they diverge, `build-provenance` won't fail but reproducibility (`Build verified: byte-for-byte`) will.

## Files

- [scripts/release.ts](scripts/release.ts) — main entry, runs the 12 steps
- [templates/release.yml](templates/release.yml) — GitHub Actions release workflow
- [templates/eslint.config.mjs](templates/eslint.config.mjs) — Obsidian scanner-friendly eslint config
- [references/scanner-warnings.md](references/scanner-warnings.md) — common Obsidian scanner findings + how to fix
- [references/changelog-style.md](references/changelog-style.md) — recommended commit + release notes format

## Related skills

- `skill-creator` — for authoring new skills (this one was made with it)
- `skillkit` — local analytics for skill usage
