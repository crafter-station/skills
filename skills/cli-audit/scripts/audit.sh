#!/usr/bin/env bash
# Deterministic layer of cli-audit.
#
# Emits facts, never a score. Every check prints one line:
#   PASS <id> <evidence>
#   FAIL <id> <evidence>
#   SEMI <id> <observation>     observed, but the verdict needs a reader
#   NA   <id> <reason>          check does not apply to this target
#   SKIP <id> <reason>          check applies but could not be run here
#
# A FAIL is a fact that a reader turns into a finding. Nothing here weighs,
# ranks, or totals: the thresholds that would do so have no source.
#
# SEMI exists because two checks observe something real whose meaning depends
# on intent the script cannot read. Reporting those as FAIL called a corpus
# CLI's documented headline feature a defect. A status that admits the limit
# beats a verdict that is confidently wrong, and SEMI is excluded from any
# pass/applicable ratio for the same reason.

set -uo pipefail

REPO=""
BIN=""
FORMAT="text"

usage() {
	cat <<'EOF'
Usage: audit.sh --repo <path> [--bin <command>] [--json]

  --repo   path to the CLI package root (the dir holding package.json)
  --bin    the installed command name, to probe runtime behavior.
           Omit to run static checks only; runtime checks report SKIP.
  --json   emit one JSON object per check on stdout (NDJSON)

Exit code is 0 when the run completed, regardless of findings. A nonzero
exit means the audit itself could not run.
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
	--repo)
		REPO="${2:-}"
		shift 2
		;;
	--bin)
		BIN="${2:-}"
		shift 2
		;;
	--json)
		FORMAT="json"
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "unknown argument: $1" >&2
		usage >&2
		exit 2
		;;
	esac
done

[ -n "$REPO" ] || {
	echo "--repo is required" >&2
	exit 2
}
[ -d "$REPO" ] || {
	echo "--repo is not a directory: $REPO" >&2
	exit 2
}
REPO="$(cd "$REPO" && pwd)"

PKG="$REPO/package.json"
SRC="$REPO/src"
[ -d "$SRC" ] || SRC="$REPO"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

emit() {
	local status="$1" id="$2" evidence="$3"
	if [ "$FORMAT" = "json" ]; then
		printf '{"status":%s,"id":%s,"evidence":%s}\n' \
			"$(jq -Rn --arg v "$status" '$v')" \
			"$(jq -Rn --arg v "$id" '$v')" \
			"$(jq -Rn --arg v "$evidence" '$v')"
	else
		printf '%-4s %-28s %s\n' "$status" "$id" "$evidence"
	fi
}

have_jq() { command -v jq >/dev/null 2>&1; }
if [ "$FORMAT" = "json" ] && ! have_jq; then
	echo "--json needs jq on PATH" >&2
	exit 2
fi

# Source files only: never let node_modules, build output, or fixtures
# answer a question about the project's own code.
srcfiles() {
	find "$SRC" -type f \( -name '*.ts' -o -name '*.js' -o -name '*.mjs' -o -name '*.tsx' \) \
		-not -path '*/node_modules/*' \
		-not -path '*/dist/*' \
		-not -path '*/build/*' \
		-not -path '*/.git/*' 2>/dev/null
}

# grep across source, returning file:line hits.
#
# `-e` is mandatory here, not stylistic: a pattern beginning with a dash
# (`--json`, the single most audited string in this file) is otherwise read by
# grep as its own option. That silently returned zero hits and turned both the
# presence check and the overload check into lies about the same flag.
sgrep() {
	local pattern="$1"
	srcfiles | tr '\n' '\0' | xargs -0 grep -nE -e "$pattern" 2>/dev/null
}

count_hits() { grep -c . 2>/dev/null || true; }

# ---------------------------------------------------------------------------
# Group A: the machine contract
# ---------------------------------------------------------------------------

# A1  --json flag exists at all.
if hits="$(sgrep '\-\-json' 2>/dev/null)" && [ -n "$hits" ]; then
	n="$(printf '%s\n' "$hits" | wc -l | tr -d ' ')"
	emit PASS json-flag-present "$n source references to --json"
else
	emit FAIL json-flag-present "no source reference to --json"
fi

# A2  Non-TTY implies machine output, and it resolves in one place.
#     cli-build: "the clean implementation is a framework-level hook rather
#     than a check repeated in every command."
#     Count only the sites that decide OUTPUT FORMAT. A TTY check guarding a
#     prompt, a consent gate, or a skill installer is a different property
#     (see prompts-never-block) and counting it as format drift reports a
#     defect where there is none.
tty_hits="$(sgrep 'stdout\.isTTY|isatty' 2>/dev/null || true)"
if [ -z "$tty_hits" ]; then
	emit FAIL nontty-implies-json "no stdout.isTTY check in source; piped output will not be machine-readable"
else
	fmt_hits="$(printf '%s\n' "$tty_hits" | grep -E 'format|json|table|output|resolved' || true)"
	if [ -z "$fmt_hits" ]; then
		emit FAIL nontty-implies-json "isTTY is read, but never to decide output format; piped output will not be machine-readable"
	else
		fmt_files="$(printf '%s\n' "$fmt_hits" | cut -d: -f1 | sort -u)"
		fmt_n="$(printf '%s\n' "$fmt_files" | wc -l | tr -d ' ')"
		short="$(printf '%s\n' "$fmt_files" | sed "s|^$REPO/||" | tr '\n' ' ')"
		# A module whose job IS the detection (detect, format, output, mode) is
		# the centralization, not evidence against it. Counting it as drift made
		# this check fail on 11 of 12 corpus CLIs, including one that resolves
		# the mode correctly, and a check that fails on almost everything stops
		# being read. What matters is how many places decide it independently of
		# that module.
		callers="$(printf '%s\n' "$fmt_files" | grep -vE '/(detect|format|output|mode|render)[^/]*\.(ts|js|mjs)$' || true)"
		caller_n="$(printf '%s\n' "$callers" | grep -c . || true)"
		if [ "$fmt_n" -eq 1 ] || [ "${caller_n:-0}" -eq 0 ]; then
			emit PASS nontty-implies-json "format resolved in a dedicated module: $short"
		else
			emit FAIL nontty-implies-json "output format decided from isTTY in $caller_n place(s) outside a detection module ($(printf '%s\n' "$callers" | sed "s|^$REPO/||" | tr '\n' ' ')); a per-command check drifts and the command that forgets is the one an agent hits"
		fi
	fi
fi

# A3  --json must mean output, never input. Two corpus CLIs overloaded it, and
#     an agent that learned --json anywhere else will pass it expecting
#     machine-readable output. A declaration taking a value is the signature.
if hits="$(sgrep '\-\-json[[:space:]]+[<[]' 2>/dev/null)" && [ -n "$hits" ]; then
	emit FAIL json-not-overloaded "--json declared with a value (input overload) at: $(printf '%s\n' "$hits" | sed "s|^$REPO/||" | cut -d: -f1,2 | tr '\n' ' ')"
else
	emit PASS json-not-overloaded "--json takes no value; reads as output mode"
fi

# A4  A schema command exists.
schema_file="$(srcfiles | xargs grep -ln 'Command("schema")\|command("schema")\|"schema"' 2>/dev/null | head -1)"
if [ -n "$schema_file" ]; then
	emit PASS schema-command-present "$(printf '%s' "$schema_file" | sed "s|^$REPO/||")"
	# A5  ...carrying a version field, so an agent can pin what it parsed.
	if grep -qE '\bversion\b' "$schema_file" 2>/dev/null; then
		emit PASS schema-has-version "version field present in $(printf '%s' "$schema_file" | sed "s|^$REPO/||")"
	else
		emit FAIL schema-has-version "schema command emits no version field; an agent cannot detect a contract change"
	fi
else
	emit FAIL schema-command-present "no schema command; agents must parse --help to introspect"
	emit NA schema-has-version "no schema command to carry a version"
fi

# A6  nextSteps in structured output.
if hits="$(sgrep 'nextSteps|next_steps' 2>/dev/null)" && [ -n "$hits" ]; then
	n="$(printf '%s\n' "$hits" | cut -d: -f1 | sort -u | wc -l | tr -d ' ')"
	emit PASS next-steps-present "nextSteps in $n file(s)"
else
	emit FAIL next-steps-present "no nextSteps in structured output; agents flail without a stated next move"
fi

# A6b No prompt may block a non-interactive run.
#
#     This is not the same property as --json, though the two travel together.
#     --json says what shape the output takes; this says what happens when the
#     code would ask a question. They separate exactly where it matters: a
#     machine-shaped invocation from a real terminal (an agent passing a JSON
#     payload while a human watches) still has a TTY, so a prompt guarded only
#     by the output mode will still block. Every prompt site must be guarded by
#     a TTY check or an explicit non-interactive flag, and must fail with a
#     structured error rather than hang.
prompt_sites="$(sgrep 'prompt\(|createInterface|readline|question\(|inquirer|@clack|enquirer' 2>/dev/null || true)"
if [ -z "$prompt_sites" ]; then
	emit PASS prompts-never-block "no interactive prompt call sites in source"
else
	prompt_files="$(printf '%s\n' "$prompt_sites" | cut -d: -f1 | sort -u)"
	unguarded=""
	while IFS= read -r f; do
		[ -n "$f" ] || continue
		if ! grep -qE 'isTTY|isatty|nonInteractive|non-interactive|process\.stdin\.isTTY|\bCI\b' "$f" 2>/dev/null; then
			unguarded="$unguarded $(printf '%s' "$f" | sed "s|^$REPO/||")"
		fi
	done <<<"$prompt_files"
	if [ -n "$unguarded" ]; then
		emit FAIL prompts-never-block "prompt call sites with no TTY or non-interactive guard in the same file:$unguarded"
	else
		emit PASS prompts-never-block "every file holding a prompt also reads a TTY or non-interactive signal"
	fi
fi

# A7  Errors go to stderr. A JSON error envelope on stdout poisons `cmd > out.json`.
err_to_stdout="$(sgrep 'console\.log\(.*(success: false|"success": ?false|\berror\b.*JSON\.stringify)' 2>/dev/null || true)"
if [ -n "$err_to_stdout" ]; then
	emit FAIL errors-on-stderr "error envelope written to stdout: $(printf '%s\n' "$err_to_stdout" | head -3 | sed "s|^$REPO/||" | tr '\n' ' ')"
else
	emit PASS errors-on-stderr "no error envelope found on stdout"
fi

# ---------------------------------------------------------------------------
# Group B: scaffolded safety that is never wired
# cli-build Phase 5: "grep for the call site. One hit, at the definition,
# means unwired." This is the highest-value class in the corpus.
# ---------------------------------------------------------------------------

# module_wired <id> <module-name-pattern> <label>
#
# Locate the file that owns the feature, read the names IT exports, then look
# for those names outside it. Enumerating likely function names does not scale:
# guessing `appendAudit|writeAudit|auditLog` missed a writer called `audit()`,
# and the widened guess then missed `auditPending`/`auditResolve`. Both times
# the script announced a missing feature that had call sites in three commands.
# The module's own export list is the only name list that cannot be wrong.
module_wired() {
	local id="$1" modpat="$2" label="$3"
	local modfile names hits real

	# A name can match more than one file: the module that writes the log and
	# the command that manages it are both called "audit". The command is a
	# consumer, so picking it inverts the question and reports the writer as
	# unwired. Prefer any candidate outside a commands directory.
	local candidates
	candidates="$(srcfiles | grep -iE "$modpat" || true)"
	if [ -z "$candidates" ]; then
		emit NA "$id" "no $label module in this CLI"
		return
	fi
	modfile="$(printf '%s\n' "$candidates" | grep -vE '/commands?/' | head -1)"
	[ -n "$modfile" ] || modfile="$(printf '%s\n' "$candidates" | head -1)"

	# Exported function and const names, which are what a call site would use.
	names="$(grep -oE '^export (async )?(function|const) [A-Za-z_][A-Za-z0-9_]*' "$modfile" 2>/dev/null |
		awk '{print $NF}' | sort -u)"
	if [ -z "$names" ]; then
		emit SKIP "$id" "$(printf '%s' "$modfile" | sed "s|^$REPO/||") exports no named function; inspect by hand"
		return
	fi

	local alt
	alt="$(printf '%s' "$names" | tr '\n' '|' | sed 's/|$//')"
	hits="$(srcfiles | grep -vF "$modfile" | tr '\n' '\0' |
		xargs -0 grep -nE "\b($alt)\(" 2>/dev/null || true)"
	real="$(printf '%s\n' "$hits" | grep -c . || true)"

	if [ "${real:-0}" -eq 0 ]; then
		emit FAIL "$id" "$label defined in $(printf '%s' "$modfile" | sed "s|^$REPO/||") but no call site outside it; --help would advertise a feature the code does not back"
	else
		local where
		where="$(printf '%s\n' "$hits" | cut -d: -f1 | sort -u | wc -l | tr -d ' ')"
		emit PASS "$id" "$label wired at $real call site(s) across $where file(s)"
	fi
}

# wired_check <id> <definition-pattern> <callsite-pattern> <label>
# Kept for features that live inline rather than in a module of their own.
wired_check() {
	local id="$1" defpat="$2" callpat="$3" label="$4"
	local defs calls def_n
	defs="$(sgrep "$defpat" 2>/dev/null || true)"
	if [ -z "$defs" ]; then
		emit NA "$id" "no $label in this CLI"
		return
	fi
	calls="$(sgrep "$callpat" 2>/dev/null || true)"
	def_n="$(printf '%s\n' "$defs" | grep -c . || true)"
	# Call sites that are not the definition itself.
	local real
	real="$(printf '%s\n' "$calls" | grep -vE 'export (async )?function|export const|function \w+\(' | grep -c . || true)"
	if [ "${real:-0}" -eq 0 ]; then
		emit FAIL "$id" "$label defined ($def_n hit(s)) but no call site outside the definition; --help would advertise a feature the code does not back"
	else
		emit PASS "$id" "$label wired at $real call site(s)"
	fi
}

wired_check dry-run-wired '\-\-dry-run|dryRun' 'dryRun|dry_run' "--dry-run"
module_wired audit-log-wired 'audit[-_.]?log|audit\.(ts|js)$|/audit\.' "audit log"
module_wired killswitch-wired 'kill[-_]?switch' "killswitch"

# B5  Presentation helpers defined and never called.
#
#     The wiring rule is usually applied to safety features, but it catches a
#     legibility defect just as well and nothing else does. A CLI exporting a
#     correct `truncateVisible` (ellipsis, visible-width aware) while three
#     call sites cut strings with a bare `.slice(0, N)` reads as solved in the
#     source and ships mid-word truncation to the reader.
presentation_mod="$(srcfiles | grep -iE '/style\.(ts|js)$|/format\.(ts|js)$' | head -1)"
if [ -z "$presentation_mod" ]; then
	emit NA presentation-helpers-used "no style or format module in this CLI"
else
	# Only helpers that RENDER. A test seam (`setColorOverride`) and a predicate
	# the module consults internally (`shouldColor`) are legitimately absent
	# from call sites, and flagging them buries the one finding that matters.
	unused=""
	while IFS= read -r fn; do
		[ -n "$fn" ] || continue
		case "$fn" in
		*Visible* | *truncate* | *pad* | *wrap* | *ellips* | *column* | *table* | *format*) ;;
		*) continue ;;
		esac
		if ! srcfiles | grep -vF "$presentation_mod" | tr '\n' '\0' |
			xargs -0 grep -qE "\b$fn\(" 2>/dev/null; then
			unused="$unused $fn"
		fi
	done <<<"$(grep -oE '^export (async )?(function|const) [A-Za-z_][A-Za-z0-9_]*' "$presentation_mod" 2>/dev/null | awk '{print $NF}' | sort -u)"
	if [ -n "$unused" ]; then
		emit FAIL presentation-helpers-used "exported but never called from $(printf '%s' "$presentation_mod" | sed "s|^$REPO/||"):$unused — check whether the work it does is being redone by hand at the call sites"
	else
		emit PASS presentation-helpers-used "every helper exported by $(printf '%s' "$presentation_mod" | sed "s|^$REPO/||") has a call site"
	fi
fi

# B6  Hand-rolled truncation on a value headed for the screen.
#
#     A bare `.slice(0, N)` is usually substring extraction and none of this
#     check's business. It only matters when the cut value is about to be
#     printed, because then the decision of whether to mark the cut is being
#     made separately at each site. Restricted to slices inside a render path
#     so the finding stays small enough to act on.
trunc_hits="$(sgrep '\.slice\(0, ?[0-9]+\)' 2>/dev/null || true)"
render_hits=""
if [ -n "$trunc_hits" ]; then
	while IFS= read -r hit; do
		[ -n "$hit" ] || continue
		f="${hit%%:*}"
		rest="${hit#*:}"
		ln="${rest%%:*}"
		# Look at a small window around the slice for a print or a row build.
		if sed -n "$((ln > 4 ? ln - 4 : 1)),$((ln + 4))p" "$f" 2>/dev/null |
			grep -qE 'console\.log|outputTable|rows\.push|headers|process\.stdout\.write'; then
			render_hits="$render_hits$hit"$'\n'
		fi
	done <<<"$trunc_hits"
fi
if [ -n "$render_hits" ]; then
	n="$(printf '%s' "$render_hits" | grep -c . || true)"
	emit FAIL truncation-centralized "$n .slice(0,N) truncation(s) on a rendered value; each decides separately whether to mark the cut, so a reader cannot tell a short value from a chopped one: $(printf '%s' "$render_hits" | head -3 | sed "s|^$REPO/||" | cut -d: -f1,2 | tr '\n' ' ')"
else
	emit PASS truncation-centralized "no hand-rolled truncation on a rendered value"
fi

# B4  Audit written before the call, not after. Two-phase, sharing an id.
# B4  Audit written before the call, not after. Two-phase, sharing an id.
#     Keyed off the same module the wiring check resolved, so the two lines
#     cannot contradict each other.
audit_mod="$(srcfiles | grep -iE 'audit[-_.]?log|audit\.(ts|js)$|/audit\.' | grep -vE '/commands?/' | head -1)"
if [ -z "$audit_mod" ]; then
	emit NA audit-two-phase "no audit log in this CLI"
elif grep -qE '\bpending\b' "$audit_mod" 2>/dev/null; then
	emit PASS audit-two-phase "a pending state exists in $(printf '%s' "$audit_mod" | sed "s|^$REPO/||"); verify by reading that it is written before the network call"
else
	emit FAIL audit-two-phase "no pending state in $(printf '%s' "$audit_mod" | sed "s|^$REPO/||"); a process killed mid-flight leaves silence, not an orphan record"
fi

# ---------------------------------------------------------------------------
# Group C: packaging and distribution
# ---------------------------------------------------------------------------

if [ -f "$PKG" ]; then
	# C1  The shebang must not name a runtime the installer may lack.
	binfield=""
	if have_jq; then
		binfield="$(jq -r 'if (.bin | type) == "string" then .bin else (.bin // {} | to_entries[0].value // "") end' "$PKG" 2>/dev/null)"
	fi
	if [ -n "$binfield" ] && [ "$binfield" != "null" ]; then
		binpath="$REPO/$binfield"
		if [ -f "$binpath" ]; then
			shebang="$(head -1 "$binpath")"
			case "$shebang" in
			*"env node"* | *"/node"*)
				emit PASS shebang-portable "$binfield: $shebang"
				;;
			*env*)
				rt="$(printf '%s' "$shebang" | sed 's|.*env ||')"
				emit FAIL shebang-portable "$binfield names '$rt'; an installer without it gets 'env: $rt: No such file or directory', a message naming no cause and no fix"
				;;
			*)
				emit FAIL shebang-portable "$binfield has no recognizable shebang: $shebang"
				;;
			esac
			# C2  A published bin pointing at TypeScript ships source, not a build.
			case "$binfield" in
			*.ts)
				emit FAIL bin-is-built "bin entry is TypeScript ($binfield); npm consumers need a build step or a TS-capable runtime"
				;;
			*)
				emit PASS bin-is-built "bin entry is $binfield"
				;;
			esac
		else
			emit FAIL bin-resolves "bin points at $binfield which does not exist in the package"
		fi
	else
		emit NA shebang-portable "no bin field; not a published CLI entry"
	fi

	# C2b The name the CLI calls itself must be the name that installs.
	#
	#     `--help` is the first screen of the product, and its Usage line is the
	#     one string a reader copies verbatim. When the program's declared name
	#     differs from the published bin, that copied line names a command the
	#     reader does not have. Found by reading real output, kept here because
	#     the two names are both on disk and a script can compare them.
	if [ -n "$binfield" ] && [ "$binfield" != "null" ] && have_jq; then
		binname="$(jq -r 'if (.bin | type) == "string" then (.name | sub("^@[^/]+/"; "")) else (.bin // {} | to_entries[0].key // "") end' "$PKG" 2>/dev/null)"
		# The declaration usually lives in the bin entry, which sits outside
		# src/ and so outside srcfiles. Read the entry itself.
		declared="$( (sgrep '\.name\("' 2>/dev/null; grep -nE '\.name\("' "$binpath" 2>/dev/null) |
			sed -n 's/.*\.name("\([^"]*\)").*/\1/p' | head -1)"
		if [ -z "$declared" ]; then
			emit SKIP program-name-matches-bin "no .name(\"...\") declaration found in source"
		elif [ "$declared" = "$binname" ]; then
			emit PASS program-name-matches-bin "program and bin agree on '$binname'"
		else
			emit FAIL program-name-matches-bin "program calls itself '$declared' but installs as '$binname'; the Usage line in --help names a command the reader does not have"
		fi
	fi

	# C3  Published with zero tests is a live anti-pattern in the corpus.
	testdir="$(find "$REPO" -maxdepth 2 -type d \( -name tests -o -name test -o -name __tests__ \) -not -path '*/node_modules/*' 2>/dev/null | head -1)"
	testfiles="$(find "$REPO" -type f \( -name '*.test.ts' -o -name '*.spec.ts' -o -name '*.test.js' \) -not -path '*/node_modules/*' 2>/dev/null | grep -c . || true)"
	if [ "${testfiles:-0}" -gt 0 ]; then
		emit PASS tests-exist "$testfiles test file(s)"
	elif [ -n "$testdir" ]; then
		emit FAIL tests-exist "a test directory exists but holds no test files"
	else
		emit FAIL tests-exist "no tests; the minimum bar is auth flow, JSON contract per command, and any signing code"
	fi

	# C4  Version drift between checkout and registry.
	name="$(have_jq && jq -r '.name // ""' "$PKG" 2>/dev/null || true)"
	local_v="$(have_jq && jq -r '.version // ""' "$PKG" 2>/dev/null || true)"
	if [ -n "$name" ] && [ -n "$local_v" ] && command -v npm >/dev/null 2>&1; then
		remote_v="$(npm view "$name" version 2>/dev/null || true)"
		if [ -z "$remote_v" ]; then
			emit NA version-drift "$name is not on the registry"
		elif [ "$remote_v" = "$local_v" ]; then
			emit PASS version-drift "checkout and registry both at $local_v"
		else
			emit FAIL version-drift "checkout is $local_v, registry serves $remote_v; the checkout is not authoritative"
		fi
	else
		emit SKIP version-drift "npm or jq unavailable, or package unnamed"
	fi

	# C5  Home-directory override, without which tests write to the real config.
	if hits="$(sgrep '_HOME\b' 2>/dev/null)" && [ -n "$hits" ]; then
		emit PASS home-override "a {APP}_HOME override exists; tests can isolate from real config"
	else
		emit FAIL home-override "no {APP}_HOME override; tests and smoke scripts write to the developer's real config and history"
	fi
else
	emit SKIP shebang-portable "no package.json at $REPO"
	emit SKIP tests-exist "no package.json at $REPO"
	emit SKIP version-drift "no package.json at $REPO"
	emit SKIP home-override "no package.json at $REPO"
fi

# C6  The agent's manual ships with the CLI.
#
#     Exclude `.agents/` and `.claude/`: a skill INSTALLED into the repo is not
#     the CLI's own manual, and matching one made a CLI look documented because
#     it had cli-build checked in. The manual lives at skills/<name>/SKILL.md.
skillmd="$(find "$REPO" -type f -name 'SKILL.md' -path '*skills*' \
	-not -path '*/node_modules/*' \
	-not -path '*/.agents/*' \
	-not -path '*/.claude/*' 2>/dev/null | head -1)"
if [ -n "$skillmd" ]; then
	if head -1 "$skillmd" | grep -q '^---$' && grep -qE '^name:' "$skillmd" && grep -qE '^description:' "$skillmd"; then
		emit PASS agent-manual "$(printf '%s' "$skillmd" | sed "s|^$REPO/||") with name and description frontmatter"
	else
		emit FAIL agent-manual "$(printf '%s' "$skillmd" | sed "s|^$REPO/||") exists but frontmatter lacks name or description; skills add will fail indistinguishably from an unpublished repo"
	fi
else
	emit FAIL agent-manual "no skills/<name>/SKILL.md; every agent rediscovers the surface through --help"
fi

# C7  Secrets must not be persisted. Identifiers may.
if hits="$(sgrep 'password.*(writeFile|JSON\.stringify)|(writeFile|JSON\.stringify).*password' 2>/dev/null)" && [ -n "$hits" ]; then
	emit FAIL secrets-not-persisted "a password appears near a write: $(printf '%s\n' "$hits" | head -3 | sed "s|^$REPO/||" | tr '\n' ' ')"
else
	emit PASS secrets-not-persisted "no password found near a persistence call"
fi

# ---------------------------------------------------------------------------
# Group D: runtime behavior. Needs the CLI on PATH, invoked by its own name.
# cli-build Phase 6: running the source file verifies a file; running the
# installed name verifies what ships.
# ---------------------------------------------------------------------------

if [ -z "$BIN" ]; then
	for id in bin-on-path stdout-clean-on-help machine-mode-no-ansi no-color-honored bare-invoke-exit failure-answers-as-data exit-codes-meaningful; do
		emit SKIP "$id" "no --bin given; runtime checks need the CLI on PATH"
	done
else
	if ! command -v "$BIN" >/dev/null 2>&1; then
		for id in bin-on-path stdout-clean-on-help machine-mode-no-ansi no-color-honored bare-invoke-exit failure-answers-as-data exit-codes-meaningful; do
			emit SKIP "$id" "$BIN is not on PATH; run 'bun link' or 'npm link' in the package first"
		done
	else
		emit PASS bin-on-path "$(command -v "$BIN")"

		# D2  Bare invoke: help text belongs on stderr with a nonzero exit.
		#     The corpus found 810 bytes on stdout here that nobody had looked for.
		"$BIN" >"$TMP/bare.out" 2>"$TMP/bare.err"
		bare_code=$?
		bare_out_bytes="$(wc -c <"$TMP/bare.out" | tr -d ' ')"
		if [ "$bare_out_bytes" -gt 0 ] && [ "$bare_code" -ne 0 ]; then
			emit FAIL bare-invoke-exit "bare invoke exits $bare_code but wrote $bare_out_bytes bytes to stdout; a failing run must leave stdout empty"
		elif [ "$bare_code" -eq 0 ] && [ "$bare_out_bytes" -gt 0 ]; then
			emit PASS bare-invoke-exit "bare invoke exits 0 with $bare_out_bytes bytes on stdout"
		else
			emit PASS bare-invoke-exit "bare invoke exits $bare_code, stdout empty"
		fi

		# D3  --help must not put diagnostics on the data stream.
		"$BIN" --help >"$TMP/help.out" 2>"$TMP/help.err"
		if grep -qE $'\033\\[' "$TMP/help.out" 2>/dev/null; then
			emit SKIP stdout-clean-on-help "help carries ANSI on a TTY-less run; inspect by hand"
		else
			emit PASS stdout-clean-on-help "no ANSI escapes in --help under a pipe"
		fi

		# D4  Machine mode carries no ANSI. Piped output is already non-TTY,
		#     so this probes the path an agent actually takes.
		if "$BIN" --json >"$TMP/json.out" 2>/dev/null || true; then
			if grep -qE $'\033\\[' "$TMP/json.out" 2>/dev/null; then
				emit FAIL machine-mode-no-ansi "ANSI escapes present in --json output; an agent parsing this gets escape bytes inside string fields"
			else
				emit PASS machine-mode-no-ansi "no ANSI escapes under --json"
			fi
		fi

		# D4b A failed command still answers as data.
		#
		#      Distinct from errors-on-stderr, and they look contradictory until
		#      the two failure kinds are separated. An invocation that never ran
		#      (bad flag, missing argument) leaves stdout empty. A command that
		#      ran and reached a negative verdict should say so as a parseable
		#      document, because reporting the failure only as prose forces an
		#      agent to parse English to learn what was wrong. Sourced from
		#      surfacer's `a_failed_lint_still_emits_a_document`.
		if "$BIN" schema __nonexistent__ >"$TMP/badres.out" 2>"$TMP/badres.err"; then
			emit SKIP failure-answers-as-data "an unknown schema resource did not fail; cannot probe the failure path here"
		elif [ -s "$TMP/badres.out" ] && command -v jq >/dev/null 2>&1 &&
			jq -e . "$TMP/badres.out" >/dev/null 2>&1; then
			emit PASS failure-answers-as-data "a rejected argument emits a parseable document on stdout"
		elif [ -s "$TMP/badres.err" ]; then
			emit PASS failure-answers-as-data "invocation error kept off stdout and reported on stderr (the other correct shape)"
		else
			emit FAIL failure-answers-as-data "a failing command produced nothing on either stream; the caller learns only the exit code"
		fi

		# D4c User error and system failure are distinguishable by exit code.
		#      An agent that cannot tell them apart retries the one that will
		#      fail the same way forever. Sourced from surfacer's
		#      `user_error_and_system_error_have_different_exit_codes`.
		"$BIN" __nosuchcommand__ >"$TMP/unknown.out" 2>/dev/null
		usr_code=$?
		if [ "$usr_code" -ne 0 ]; then
			emit PASS exit-codes-meaningful "unknown command exits $usr_code; separating user error from system failure needs a forced system fault, not probed here"
		elif [ -s "$TMP/unknown.out" ]; then
			# Exiting 0 with output means the argument was absorbed as INPUT
			# rather than rejected. That is a defect when the CLI has no such
			# shorthand, and it is the product when it does: one corpus CLI
			# routes a bare word to a generate command on purpose, documented
			# in --help and commented at the call site. The check cannot tell
			# those apart, so it reports the observation and says so rather
			# than calling a deliberate design a failure.
			emit SEMI exit-codes-meaningful "unknown command exited 0 and wrote $(wc -c <"$TMP/unknown.out" | tr -d ' ') bytes to stdout; the argument was absorbed as input. Read --help: a documented bare-word shorthand makes this the design, its absence makes it a typo that reads as a successful run"
		else
			emit FAIL exit-codes-meaningful "unknown command exited 0 with empty stdout; success and user error are indistinguishable"
		fi

		# D5  NO_COLOR removes styling without changing content.
		"$BIN" --help >"$TMP/nc_off.out" 2>/dev/null || true
		NO_COLOR=1 "$BIN" --help >"$TMP/nc_on.out" 2>/dev/null || true
		if [ -s "$TMP/nc_off.out" ] || [ -s "$TMP/nc_on.out" ]; then
			off_stripped="$(sed $'s/\033\\[[0-9;]*m//g' "$TMP/nc_off.out")"
			on_stripped="$(sed $'s/\033\\[[0-9;]*m//g' "$TMP/nc_on.out")"
			if [ "$off_stripped" = "$on_stripped" ]; then
				emit PASS no-color-honored "NO_COLOR changes styling only, content identical"
			else
				emit FAIL no-color-honored "NO_COLOR changed the content, not just the styling"
			fi
		else
			emit SKIP no-color-honored "--help produced no output to compare"
		fi
	fi
fi

# ---------------------------------------------------------------------------
# Group E: what this layer cannot decide.
# Named explicitly so a clean run is never read as a clean CLI. The first CLI
# built with cli-build passed every mechanical gate and was unreadable.
# ---------------------------------------------------------------------------

for id in \
	human-default-view \
	metric-direction \
	scale-calibration \
	vertical-repetition \
	safety-sized-to-damage \
	noun-verb-consistency \
	dry-run-exercises-real-path \
	help-is-first-screen; do
	emit NA "$id" "judgment check: requires reading real output, see SKILL.md step 3"
done
