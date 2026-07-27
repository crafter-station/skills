# Build and runtime

The question is not which runtime you prefer. It is **who has to install something before your CLI runs.**

## The matrix

| Audience | Target | Prerequisite for the user | Use when |
|---|---|---|---|
| You, from source | Runtime shebang, no build | That runtime installed | Internal tools, personal automation |
| JS-ecosystem developers | Build to Node, publish to npm | Node (they have it) | The default for anything public |
| Anyone | Compile to a native binary | Nothing | Consumer CLIs, mixed audiences |

## The evidence

Measured across 14 CLIs with real code, four of them published to a registry.

The uncomfortable finding first: **three of the four published packages ship a runtime-specific shebang.** Only one emits `#!/usr/bin/env node`. So publishing with a non-Node shebang is not blocked by anything. It works, right up until a user without that runtime installs it and gets:

```
env: bun: No such file or directory
```

That message names no cause and no fix. The package looks broken rather than under-specified.

So the argument is about the person installing it, not about a correlation between shebang and publication. There is no such correlation.

**What the distribution split does show:**

| Target | Built | Reached a registry |
|---|---|---|
| Runtime shebang, no build | 6 | 3 |
| Build step to Node | 4 | 3 |
| Compiled binary | 4 | 1 |

Building to Node has the best ratio, and it is also the only target where nothing extra has to be installed by someone who already writes JavaScript.

**This corrects advice from the skill this one replaces**, which stated "always compile with the alternative runtime's bundler" as a rule. The newest CLIs in the corpus skip the build step entirely. Both halves of that advice were wrong: there is no universal build rule, only an audience question.

## The rule that keeps all three doors open

**Write against Node's API surface** (`fs`, `path`, `process`, `http`), not runtime-specific APIs.

Then the target is a build-time decision instead of a rewrite. Start internal with a shebang, publish to npm later, compile to a binary after that, all without touching the source.

Corroboration from real work: making a project compile to a native binary required migrating it to Node APIs first. The same change that unlocked native compilation also made the code portable across runtimes. Both goals point the same way.

## Target 1: source, no build

```json
{ "bin": { "mycli": "./bin/mycli.ts" } }
```

With a runtime shebang on a TypeScript file executed directly. Zero build, instant iteration, no dist directory.

Correct for: internal tooling, anything installed by `git clone`, CLIs where you are the only user.

Not correct for: anything you publish. Do not make strangers install a runtime to run your tool.

## Target 2: build to Node, publish to npm

The proven path for public distribution.

- Use the fast runtime as your toolchain for dev, test, and package management. That part does not change.
- Build with `tsup`, or with your bundler's Node target, and emit a `#!/usr/bin/env node` shebang.
- Set `engines.node` to what you tested. Test on the lowest version you claim.
- Verify the built artifact actually runs under plain `node`, not just under your dev runtime. This is the check people skip.

```jsonc
{
  "bin": { "mycli": "./dist/cli.js" },
  "engines": { "node": ">=20" },
  "files": ["dist"]
}
```

**Guard against version drift.** One corpus CLI has a local `package.json` claiming one version while the published package resolves to a much later one under a different name. Check what is actually on the registry before assuming your local checkout is the source of truth.

## Target 3: native binary

A TypeScript-to-native compiler removes the runtime question entirely. A hello-world binary lands around 320KB, starts in roughly 4ms, and links against nothing but the system library. The equivalent on Node needs roughly 120MB of runtime and 35ms. macOS, Linux, and Windows.

**The gate: run the coverage report before committing to this target.**

```bash
scriptc coverage src/cli.ts
```

It reports, statement by statement, what compiles to native code, what needs the embedded dynamic engine, and what blocks the rest. A measured run over a real CLI codebase came in at 94 percent of just over a thousand statements compiling statically, with eight modules at 100 percent.

Three tiers, all explicit:

- **Tier 1, static:** ordinary TypeScript (classes, closures, async/await, the standard library, and Node's `fs`/`path`/`process`/`http` surface) compiles to native with no engine in the binary.
- **Tier 2, dynamic (opt-in):** an embedded JS engine of roughly 620KB executes what cannot compile statically. In practice this is mostly JavaScript shipped by npm dependencies, and `any`-typed code. Values crossing back into static code are validated at runtime.
- **Tier 3, rejected:** fails the build with an error code, a code frame, and usually a rewrite hint. Nothing is silently miscompiled.

**What this means in practice:** a single npm dependency that ships plain JavaScript can pull in the dynamic engine and add most of a megabyte. The coverage report names the site. If your dependency tree is heavy on prebuilt JS, either replace those dependencies or accept the dynamic tier.

**Status:** early versions. Treat it as a target worth measuring rather than a default, and re-measure after dependency changes. The compiler is under active development and rejections that block you today may not tomorrow.

## Choosing a CLI framework

Observed in the corpus: a mature argument-parsing framework in most, hand-rolled parsing in several of the newest and smallest.

- **Framework** for anything with nested subcommands, generated help, or more than a handful of commands.
- **Hand-rolled** for single-purpose tools with under five commands. It removes a dependency and you control the error messages.

One framework gotcha worth knowing, documented in a corpus CLI's own source comments: with Commander, parent-level global options are consumed before reaching a subcommand's action handler. Declaring the options on the subcommands instead ensures the handler receives them. If your global flags mysteriously arrive undefined in nested commands, that is why.

## Testing what you ship

Test the built artifact, not only the source.

- Run the compiled entry point end to end and assert on exit codes.
- Assert on machine-mode output shape, which is your published contract.
- If you publish a binary, run the binary in CI on each target platform.

Two published packages in the corpus have zero tests. Both are installable today. The minimum bar is: the auth flow, the JSON contract per command, and any signing or crypto code.
