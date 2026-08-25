#!/usr/bin/env bash
# Coverage artifact for cli-audit.
#
# Enumerates a CLI's own command surface by walking `--help`, then compares it
# against the commands an audit actually exercised. Emits the ratio.
#
# Why this exists: an audit of four commands and an audit of sixty produce prose
# reports that read the same. The first pass of this skill covered 4 of ~60 and
# said so only in a closing section; it took the reader asking to surface it.
# A ratio the report cannot omit turns partial coverage from a disclaimer into
# a number.
#
# Usage:
#   coverage.sh --bin <name>                    enumerate the surface
#   coverage.sh --bin <name> --exercised <file> enumerate and compare
#
# `--exercised` takes a file with one command per line, as invoked without the
# binary name, e.g. "f616 declare". Lines starting with # are ignored.

set -uo pipefail

BIN=""
EXERCISED=""
FORMAT="text"
MAXDEPTH=3

usage() {
	sed -n '2,22p' "$0" | sed 's|^# \?||'
}

while [ $# -gt 0 ]; do
	case "$1" in
	--bin)
		BIN="${2:-}"
		shift 2
		;;
	--exercised)
		EXERCISED="${2:-}"
		shift 2
		;;
	--json)
		FORMAT="json"
		shift
		;;
	--max-depth)
		MAXDEPTH="${2:-3}"
		shift 2
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "unknown argument: $1" >&2
		exit 2
		;;
	esac
done

[ -n "$BIN" ] || {
	echo "--bin is required" >&2
	exit 2
}
command -v "$BIN" >/dev/null 2>&1 || {
	echo "$BIN is not on PATH; link the package first (bun link / npm link)" >&2
	exit 2
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
SURFACE="$TMP/surface.txt"
: >"$SURFACE"

# Parse the Commands: block of a --help screen. Commander, oclif, yargs and
# clap all render it as an indented list whose first token is the command name,
# so this covers the frameworks in the corpus without knowing which is in use.
subcommands_of() {
	local path="$1" block indent
	# shellcheck disable=SC2086
	block="$($BIN $path --help 2>/dev/null | sed -n '/^Commands:/,/^$/p' | tail -n +2)"
	[ -n "$block" ] || return 0

	# A long description wraps, and its continuation lines are indented DEEPER
	# than the command column. Taking the first word of every indented line
	# harvests those continuations as commands: `f616 declarar` yielded
	# `deuda`, `cambiar` and `presentado`, none of which exist, and each was
	# then walked as its own namespace. Anchor on the command column instead:
	# the smallest indent in the block is where names start, and only lines at
	# exactly that indent carry one.
	indent="$(printf '%s\n' "$block" | grep -E '^[[:space:]]+[a-z]' |
		sed 's/[^ ].*//' | awk '{print length}' | sort -n | head -1)"
	[ -n "$indent" ] || return 0

	printf '%s\n' "$block" |
		grep -E "^ {$indent}[a-z][a-z0-9:_-]*([[:space:]]|$)" |
		awk '{print $1}' |
		grep -vE '^help$' |
		sort -u || true
}

# Walk breadth-first to MAXDEPTH. A CLI that nests deeper than this is unusual
# and the depth is reported, never silently truncated.
walk() {
	local path="$1" depth="$2"
	[ "$depth" -gt "$MAXDEPTH" ] && return
	local kids
	kids="$(subcommands_of "$path")"
	if [ -z "$kids" ]; then
		[ -n "$path" ] && printf '%s\n' "$path" >>"$SURFACE"
		return
	fi
	# A node with children is itself a namespace, not a leaf command. Record it
	# so `--help` coverage of the namespace is visible, but mark it.
	[ -n "$path" ] && printf '%s\t(namespace)\n' "$path" >>"$SURFACE"
	local k
	while IFS= read -r k; do
		[ -n "$k" ] || continue
		walk "${path:+$path }$k" "$((depth + 1))"
	done <<<"$kids"
}

walk "" 1

leaves="$(grep -v '(namespace)' "$SURFACE" | sort -u)"
namespaces="$(grep '(namespace)' "$SURFACE" | cut -f1 | sort -u)"
n_leaf="$(printf '%s\n' "$leaves" | grep -c . || true)"
n_ns="$(printf '%s\n' "$namespaces" | grep -c . || true)"

if [ -z "$EXERCISED" ]; then
	if [ "$FORMAT" = "json" ]; then
		printf '{"bin":"%s","leafCommands":%s,"namespaces":%s,"maxDepth":%s,"surface":[' \
			"$BIN" "$n_leaf" "$n_ns" "$MAXDEPTH"
		printf '%s\n' "$leaves" | awk 'NF{printf "%s\"%s\"", (NR>1?",":""), $0}'
		printf ']}\n'
	else
		echo "Surface of $BIN: $n_leaf leaf command(s) across $n_ns namespace(s), walked to depth $MAXDEPTH"
		echo
		printf '%s\n' "$leaves" | sed 's/^/  /'
	fi
	exit 0
fi

[ -f "$EXERCISED" ] || {
	echo "--exercised file not found: $EXERCISED" >&2
	exit 2
}

ran="$(grep -vE '^\s*(#|$)' "$EXERCISED" | sed 's/[[:space:]]*$//' | sort -u)"
n_ran="$(printf '%s\n' "$ran" | grep -c . || true)"

# Only count commands that exist in the surface. An entry that matches nothing
# is a typo or a stale note, and silently counting it inflates coverage.
covered="$(comm -12 <(printf '%s\n' "$leaves") <(printf '%s\n' "$ran"))"
unknown="$(comm -13 <(printf '%s\n' "$leaves") <(printf '%s\n' "$ran"))"
missed="$(comm -23 <(printf '%s\n' "$leaves") <(printf '%s\n' "$ran"))"
n_cov="$(printf '%s\n' "$covered" | grep -c . || true)"
n_unknown="$(printf '%s\n' "$unknown" | grep -c . || true)"

pct=0
[ "$n_leaf" -gt 0 ] && pct=$((n_cov * 100 / n_leaf))

if [ "$FORMAT" = "json" ]; then
	printf '{"bin":"%s","leafCommands":%s,"exercised":%s,"coveragePct":%s,"unmatchedEntries":%s,"notExercised":[' \
		"$BIN" "$n_leaf" "$n_cov" "$pct" "$n_unknown"
	printf '%s\n' "$missed" | awk 'NF{printf "%s\"%s\"", (NR>1?",":""), $0}'
	printf ']}\n'
else
	echo "Coverage of $BIN: $n_cov of $n_leaf leaf commands exercised ($pct%)"
	[ "$n_ran" -ne "$n_cov" ] && echo "  note: $n_unknown exercised entr(ies) matched no command in the surface"
	echo
	echo "Not exercised:"
	printf '%s\n' "$missed" | sed 's/^/  /'
fi
