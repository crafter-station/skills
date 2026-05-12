# Obsidian scanner — common warnings + fixes

The Obsidian Community automated review system (launched 2026-05-12) lints every plugin release via `eslint-plugin-obsidianmd` and a build-provenance checker. The full source of truth is https://github.com/obsidianmd/eslint-plugin — this file is a cheat sheet for the warnings you'll hit on a real plugin and the canonical fix.

## Risk-level findings (block "Add to Obsidian")

### `minAppVersion` lower than required API

Workspace methods like `revealLeaf`, certain `Editor` APIs, and `Platform.isWayland` need a minimum Obsidian version. The scanner cross-checks every API call against the `minAppVersion` in `manifest.json`.

Fix: bump `minAppVersion` in `manifest.json` AND add the bump to `versions.json`:

```json
{
  "0.7.4": "1.7.2"
}
```

## Warnings (don't block install but hurt scorecard)

### `Use 'window.setTimeout()' instead of 'activeWindow.setTimeout()'`

`activeWindow` is for DOM operations on the currently focused popout (`activeWindow.document.createElement`, etc). Timer functions go on `window`.

```ts
// wrong
activeWindow.setTimeout(() => ..., 10);
activeWindow.clearTimeout(timerId);

// right
window.setTimeout(() => ..., 10);
window.clearTimeout(timerId);
```

### `Avoid using 'global' / 'globalThis'`

The scanner can't tell `options.global` (a property name) from the JS `global` object — it flags either. Two paths:

- **Property name collision**: rename it. `options.global` → `options.globalInstall`.
- **`globalThis.require` for Electron**: use `window.require` instead.

```ts
const req = (window as unknown as { require?: (id: string) => unknown }).require;
```

### `Use 'createSvg("svg")' instead of 'document.createElementNS(...)'`

Obsidian exposes `createSvg` and `createEl` as globals. They handle popout window context automatically.

```ts
// wrong
const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
const polyline = document.createElementNS("http://www.w3.org/2000/svg", "polyline");

// right
const svg = createSvg("svg");
const polyline = createSvg("polyline");
```

### `Use 'activeDocument' instead of 'document' for popout window compatibility`

Document references that don't target the main window must use `activeDocument`. This applies to `addEventListener`, `body.classList`, querySelector at the document level.

```ts
// wrong
document.addEventListener("click", handler);
document.body.classList.contains("theme-dark");

// right
activeDocument.addEventListener("click", handler);
activeDocument.body.classList.contains("theme-dark");
```

### `Unsafe return / member access / call of a value of type any`

The scanner runs `typescript-eslint` with `recommendedTypeChecked`. All `JSON.parse`, third-party API responses (`requestUrl().json`), and dynamic imports are typed `any` by default. Cast at the seam:

```ts
// wrong
const data = JSON.parse(raw);
return data.skills;

// right
interface SearchResponse { skills?: Skill[] }
const data = JSON.parse(raw) as SearchResponse;
return data.skills ?? [];
```

### `Unsafe call of a type that could not be resolved` on electron `shell`

Direct `import { shell } from "electron"` doesn't have types in the Obsidian env. Use a typed helper:

```ts
// src/utils/shell.ts
interface ElectronShell {
  openExternal(url: string): Promise<void>;
  showItemInFolder(fullPath: string): void;
}

function getElectronShell(): ElectronShell | null {
  try {
    const req = (window as unknown as { require?: (id: string) => unknown }).require;
    if (typeof req !== "function") return null;
    const mod = req("electron") as { shell: ElectronShell } | undefined;
    return mod?.shell ?? null;
  } catch {
    return null;
  }
}

export function openExternal(url: string): void {
  const shell = getElectronShell();
  if (shell) {
    void shell.openExternal(url);
    return;
  }
  window.open(url, "_blank");
}
```

### `Unused parameter`

Prefix with underscore: `function foo(_unusedArg: string)`. Don't delete — keeps signature compat with callers.

## CSS warnings

### `Avoid !important`

Subclassify or double-up the selector to win specificity:

```css
/* wrong */
.as-hidden { display: none !important; }

/* right — double class wins by specificity */
.as-container .as-hidden,
.as-hidden.as-hidden { display: none; }
```

### `Unexpected duplicate selector ".foo", first used at line N`

Merge them. Don't redeclare. If two rules sit far apart for organization, consolidate or move them together.

### `Unexpected unknown at-rule "@theme"`

False positive for Tailwind v4. If it's in your landing site, make sure `web/**` is in the eslint ignores block of `eslint.config.mjs`.

## Build verification

The scanner reproduces your build byte-by-byte from source. To pass:

- Don't commit a `main.js` that wasn't produced by `bun run build` against the current source
- Don't post-process `main.js` (no minifier outside esbuild, no manual edits)
- Lock your dependencies (`bun.lockb` or `package-lock.json` checked in)
- The workflow uses `bun install --frozen-lockfile` to match exactly

## Artifact attestation

Add `actions/attest-build-provenance@v2` to your release workflow with `id-token: write` and `attestations: write` permissions. The scanner shows a green `Pass — Build verified` once this lands. See [templates/release.yml](../templates/release.yml).

## `web/`, `assets/`, `scripts/` flooding warnings

The scanner walks the whole repo. If your plugin ships a landing site, marketing assets, or release scripts in subdirectories, they get linted too. Hoist an ignore block ABOVE the `obsidianmd.configs.recommended` spread:

```js
export default defineConfig([
  { ignores: ["main.js", "node_modules/**", "*.mjs", "web/**", "assets/**", "scripts/**"] },
  ...obsidianmd.configs.recommended,
  // ...
]);
```

Order matters — `obsidianmd.configs.recommended` adds `files: ["**/*.ts", "**/*.tsx"]`. If your ignores come after, they're applied to a smaller set; if they come before, they win.
