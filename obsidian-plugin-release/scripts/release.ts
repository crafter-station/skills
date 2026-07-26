#!/usr/bin/env bun
/**
 * obsidian-plugin-release — atomic release for Obsidian community plugins.
 *
 * Usage:
 *   release.ts <version>              # full ship
 *   release.ts <version> --dry        # show diff, no writes, no network
 *   release.ts --check                # audit current state
 *   release.ts <version> --allow-dirty
 *   release.ts <version> --first      # skip "version already in versions.json" guard
 */

import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { spawnSync } from "node:child_process";

const cwd = process.cwd();
const args = process.argv.slice(2);

function die(msg: string): never {
	console.error(`error: ${msg}`);
	process.exit(1);
}

function run(cmd: string, opts: { capture?: boolean; allowFail?: boolean } = {}): string {
	const result = spawnSync("sh", ["-c", cmd], {
		stdio: opts.capture ? "pipe" : "inherit",
		encoding: "utf-8",
	});
	if (result.status !== 0 && !opts.allowFail) {
		die(`command failed: ${cmd}`);
	}
	return result.stdout?.trim() ?? "";
}

function readJson<T>(path: string): T {
	return JSON.parse(readFileSync(path, "utf-8")) as T;
}

function writeJson(path: string, obj: unknown): void {
	const raw = `${JSON.stringify(obj, null, "\t")}\n`;
	writeFileSync(path, raw);
}

interface Manifest {
	id: string;
	version: string;
	minAppVersion: string;
	[k: string]: unknown;
}

function loadPluginState(): {
	manifest: Manifest;
	manifestPath: string;
	versionsPath: string;
	pkgPath: string | null;
	versions: Record<string, string>;
} {
	const manifestPath = join(cwd, "manifest.json");
	const versionsPath = join(cwd, "versions.json");
	const pkgPath = join(cwd, "package.json");

	if (!existsSync(manifestPath)) die("manifest.json not found — not an Obsidian plugin");
	if (!existsSync(versionsPath)) die("versions.json not found — not an Obsidian plugin");

	const manifest = readJson<Manifest>(manifestPath);
	if (!manifest.id || !manifest.version || !manifest.minAppVersion) {
		die("manifest.json missing required keys (id, version, minAppVersion)");
	}
	const versions = readJson<Record<string, string>>(versionsPath);

	return {
		manifest,
		manifestPath,
		versionsPath,
		pkgPath: existsSync(pkgPath) ? pkgPath : null,
		versions,
	};
}

function semverValid(v: string): boolean {
	return /^\d+\.\d+\.\d+$/.test(v);
}

function gitClean(): boolean {
	const status = run("git status --porcelain", { capture: true });
	return status.length === 0;
}

function currentBranch(): string {
	return run("git rev-parse --abbrev-ref HEAD", { capture: true });
}

function hasWorkflow(): boolean {
	return existsSync(join(cwd, ".github/workflows/release.yml"));
}

function commandCheck(): void {
	const state = loadPluginState();
	const lastVersion = Object.keys(state.versions).pop() ?? "(none)";
	const branch = gitClean() ? currentBranch() : `${currentBranch()} (dirty)`;
	const workflow = hasWorkflow() ? "✓ present" : "✗ missing — run `scaffold-workflow`";

	console.log(`plugin id:       ${state.manifest.id}`);
	console.log(`manifest version: ${state.manifest.version}`);
	console.log(`last released:    ${lastVersion}`);
	console.log(`min app version:  ${state.manifest.minAppVersion}`);
	console.log(`branch:           ${branch}`);
	console.log(`workflow:         ${workflow}`);

	if (state.manifest.version !== lastVersion && lastVersion !== "(none)") {
		console.log(`\n⚠ manifest version (${state.manifest.version}) differs from versions.json head (${lastVersion}).`);
	}
}

function scaffoldWorkflow(force = false): void {
	const target = join(cwd, ".github/workflows/release.yml");
	if (existsSync(target) && !force) die("release.yml already exists — pass --force to overwrite");

	const templatePath = join(import.meta.dir, "../templates/release.yml");
	const template = readFileSync(templatePath, "utf-8");

	const ghDir = join(cwd, ".github/workflows");
	run(`mkdir -p "${ghDir}"`);
	writeFileSync(target, template);
	console.log(`✓ wrote ${target}`);
	console.log("commit and push, then tag a release to trigger the workflow.");
}

function bumpFiles(state: ReturnType<typeof loadPluginState>, version: string, dry: boolean): string[] {
	const touched: string[] = [];

	const newManifest = { ...state.manifest, version };
	if (dry) {
		console.log(`would write manifest.json: version ${state.manifest.version} → ${version}`);
	} else {
		writeJson(state.manifestPath, newManifest);
	}
	touched.push("manifest.json");

	if (state.pkgPath) {
		const pkg = readJson<Record<string, unknown>>(state.pkgPath);
		if (dry) {
			console.log(`would write package.json: version ${String(pkg.version)} → ${version}`);
		} else {
			writeJson(state.pkgPath, { ...pkg, version });
		}
		touched.push("package.json");
	}

	const newVersions = { ...state.versions, [version]: state.manifest.minAppVersion };
	if (dry) {
		console.log(`would append versions.json: "${version}": "${state.manifest.minAppVersion}"`);
	} else {
		writeJson(state.versionsPath, newVersions);
	}
	touched.push("versions.json");

	return touched;
}

function commandRelease(version: string, opts: { dry: boolean; allowDirty: boolean; first: boolean }): void {
	if (!semverValid(version)) die(`invalid version "${version}" — expected MAJOR.MINOR.PATCH`);

	const state = loadPluginState();

	if (!opts.first && state.versions[version]) {
		die(`version ${version} already exists in versions.json`);
	}

	if (!gitClean() && !opts.allowDirty) {
		die("working tree dirty — commit or stash first, or pass --allow-dirty");
	}

	if (!hasWorkflow()) {
		die(".github/workflows/release.yml missing — run `release scaffold-workflow` first");
	}

	console.log(`releasing ${state.manifest.id} ${state.manifest.version} → ${version}${opts.dry ? " (dry run)" : ""}`);

	const touched = bumpFiles(state, version, opts.dry);

	if (opts.dry) {
		console.log("\nwould run:");
		console.log("  bun run build");
		console.log("  bunx eslint src/  # if src/ exists");
		console.log(`  git add ${touched.join(" ")} main.js styles.css`);
		console.log(`  git commit -m "chore: release ${version}"`);
		console.log(`  git push origin ${currentBranch()}`);
		console.log(`  git tag -a ${version} -m "Release ${version}"`);
		console.log(`  git push origin ${version}`);
		console.log("  gh run watch <latest>");
		return;
	}

	console.log("\n→ building...");
	run("bun run build");

	if (existsSync(join(cwd, "src"))) {
		console.log("\n→ linting...");
		run("bunx eslint src/", { allowFail: false });
	}

	const stagedFiles = [...touched];
	if (existsSync(join(cwd, "main.js"))) stagedFiles.push("main.js");
	if (existsSync(join(cwd, "styles.css"))) stagedFiles.push("styles.css");

	console.log("\n→ staging + committing...");
	run(`git add ${stagedFiles.map((f) => `"${f}"`).join(" ")}`);
	run(`git commit -m "chore: release ${version}"`);

	const branch = currentBranch();
	console.log(`\n→ pushing ${branch}...`);
	run(`git push origin ${branch}`);

	console.log(`\n→ tagging ${version}...`);
	run(`git tag -a ${version} -m "Release ${version}"`);
	run(`git push origin ${version}`);

	console.log("\n→ waiting for workflow...");
	// give Actions ~5s to pick up the tag push
	run("sleep 5");
	const runId = run(`gh run list --workflow release.yml --limit 1 --json databaseId --jq '.[0].databaseId'`, { capture: true });
	if (runId) {
		run(`gh run watch ${runId} --exit-status`);
	} else {
		console.log("⚠ could not find workflow run — check `gh run list` manually");
	}

	console.log("\n→ verifying release assets...");
	const assets = run(`gh release view ${version} --json assets --jq '[.assets[].name] | join(",")'`, { capture: true });
	console.log(`assets: ${assets}`);

	const id = state.manifest.id;
	console.log("\n✓ release complete");
	console.log(`  release:   https://github.com/${run("gh repo view --json nameWithOwner --jq .nameWithOwner", { capture: true })}/releases/tag/${version}`);
	console.log(`  community: https://community.obsidian.md/plugins/${id}`);
	console.log(`  deeplink:  obsidian://show-plugin?id=${id}`);
}

// --- arg parsing ---
const flags = new Set(args.filter((a) => a.startsWith("--")));
const positional = args.filter((a) => !a.startsWith("--"));

if (positional[0] === "scaffold-workflow") {
	scaffoldWorkflow(flags.has("--force"));
} else if (flags.has("--check") || positional[0] === "check") {
	commandCheck();
} else if (positional[0]) {
	commandRelease(positional[0], {
		dry: flags.has("--dry"),
		allowDirty: flags.has("--allow-dirty"),
		first: flags.has("--first"),
	});
} else {
	console.log("usage:");
	console.log("  release <version>              full ship");
	console.log("  release <version> --dry        preview");
	console.log("  release --check                audit current state");
	console.log("  release scaffold-workflow      add .github/workflows/release.yml");
	process.exit(1);
}
