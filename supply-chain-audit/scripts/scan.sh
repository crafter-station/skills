#!/usr/bin/env bash
# supply-chain-audit / scan.sh
# Read-only scanner. Emits a markdown report to stdout.
# Usage: scan.sh [project_root ...]
# Defaults: $HOME if no roots given.

set -u
# Deliberately NOT set -e — a missing tool on one phase shouldn't abort the others.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
IOCS_FILE="$SKILL_DIR/iocs.json"

if [ ! -f "$IOCS_FILE" ]; then
  echo "ERROR: iocs.json not found at $IOCS_FILE" >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required (brew install jq / apt install jq)" >&2
  exit 2
fi

# Roots default to $HOME, but caller can narrow.
if [ "$#" -eq 0 ]; then
  ROOTS=("$HOME")
else
  ROOTS=("$@")
fi

OS="$(uname -s)"
HOSTNAME_VAL="$(hostname 2>/dev/null || echo unknown)"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
IOC_VERSION="$(jq -r '.version' "$IOCS_FILE")"

# Staleness check — warn if IOC pack is >30 days old.
# Empty result if date parsing fails (cross-platform: GNU vs BSD date).
ioc_epoch="$(date -j -f '%Y-%m-%d' "$IOC_VERSION" +%s 2>/dev/null || date -d "$IOC_VERSION" +%s 2>/dev/null || echo 0)"
now_epoch="$(date +%s)"
STALENESS_WARNING=""
if [ "$ioc_epoch" -gt 0 ]; then
  age_days=$(( (now_epoch - ioc_epoch) / 86400 ))
  if [ "$age_days" -gt 30 ]; then
    STALENESS_WARNING="> **WARNING:** IOC pack is ${age_days} days old (last updated ${IOC_VERSION}). New supply-chain campaigns may have been disclosed since. Update \`iocs.json\` from upstream before trusting a CLEAN verdict."
  fi
fi

# Counters for verdict.
FAIL_COUNT=0
PASS_COUNT=0
SKIP_COUNT=0

# Buffers for sections.
CHECKLIST=""
AT_RISK=""
PHASE_A_FAILS=0
PHASE_B_FAILS=0
PHASE_C_FAILS=0

row() {
  # row campaign check result [evidence]
  local campaign="$1" check="$2" result="$3" evidence="${4:-}"
  case "$result" in
    PASS) PASS_COUNT=$((PASS_COUNT+1)) ;;
    FAIL) FAIL_COUNT=$((FAIL_COUNT+1)) ;;
    skipped) SKIP_COUNT=$((SKIP_COUNT+1)) ;;
  esac
  local cell_evidence=""
  if [ -n "$evidence" ]; then
    cell_evidence=" — \`${evidence//|/\\|}\`"
  fi
  CHECKLIST="${CHECKLIST}| ${campaign} | ${check}${cell_evidence} | ${result} |
"
}

expand_path() {
  # Expand ~ and $VAR, no other shell magic.
  local p="$1"
  p="${p/#\~/$HOME}"
  # shellcheck disable=SC2086
  echo $p
}

# ───────────────────────────────────────────────────────────────
# PHASE A — Persistence IOCs
# ───────────────────────────────────────────────────────────────
phase_a() {
  local n_campaigns
  n_campaigns="$(jq '.campaigns | length' "$IOCS_FILE")"
  for i in $(seq 0 $((n_campaigns-1))); do
    local cid cname
    cid="$(jq -r ".campaigns[$i].id" "$IOCS_FILE")"
    cname="$(jq -r ".campaigns[$i].name" "$IOCS_FILE")"

    # Build path list by OS.
    local paths_json
    case "$OS" in
      Darwin)  paths_json="$(jq -c ".campaigns[$i].persistence.macos // [], .campaigns[$i].persistence.shared // []" "$IOCS_FILE" | jq -s 'add')" ;;
      Linux)   paths_json="$(jq -c ".campaigns[$i].persistence.linux // [], .campaigns[$i].persistence.shared // []" "$IOCS_FILE" | jq -s 'add')" ;;
      MINGW*|CYGWIN*|MSYS*) paths_json="$(jq -c ".campaigns[$i].persistence.windows // [], .campaigns[$i].persistence.shared // []" "$IOCS_FILE" | jq -s 'add')" ;;
      *)       paths_json="$(jq -c ".campaigns[$i].persistence.shared // []" "$IOCS_FILE")" ;;
    esac

    local n_paths
    n_paths="$(echo "$paths_json" | jq 'length')"
    if [ "$n_paths" -eq 0 ]; then
      row "$cname" "persistence (no paths for this OS)" "skipped" ""
      continue
    fi

    for j in $(seq 0 $((n_paths-1))); do
      local raw expanded
      raw="$(echo "$paths_json" | jq -r ".[$j]")"

      # Windows registry path: check via reg query if available.
      if [[ "$raw" == HKCU* || "$raw" == HKLM* ]]; then
        if command -v reg >/dev/null 2>&1; then
          local key val
          key="${raw%\\*}"
          val="${raw##*\\}"
          if reg query "$key" /v "$val" >/dev/null 2>&1; then
            row "$cname" "registry $raw" "FAIL" "key present"
            PHASE_A_FAILS=$((PHASE_A_FAILS+1))
          else
            row "$cname" "registry $raw" "PASS" ""
          fi
        else
          row "$cname" "registry $raw" "skipped" "reg not available"
        fi
        continue
      fi

      expanded="$(expand_path "$raw")"
      if [ -e "$expanded" ]; then
        row "$cname" "persistence $raw" "FAIL" "$expanded exists"
        PHASE_A_FAILS=$((PHASE_A_FAILS+1))
      else
        row "$cname" "persistence $raw" "PASS" ""
      fi
    done
  done
}

# ───────────────────────────────────────────────────────────────
# PHASE B — Code & cache IOCs
# ───────────────────────────────────────────────────────────────
phase_b() {
  local n_campaigns
  n_campaigns="$(jq '.campaigns | length' "$IOCS_FILE")"

  # Build root globs.
  local find_roots=()
  for r in "${ROOTS[@]}"; do
    [ -d "$r" ] && find_roots+=("$r")
  done
  if [ "${#find_roots[@]}" -eq 0 ]; then
    row "ALL" "Phase B (no valid roots)" "skipped" ""
    return
  fi

  for i in $(seq 0 $((n_campaigns-1))); do
    local cid cname
    cid="$(jq -r ".campaigns[$i].id" "$IOCS_FILE")"
    cname="$(jq -r ".campaigns[$i].name" "$IOCS_FILE")"

    # B1: compromised scopes — list any installed @scope/* in node_modules.
    local scopes
    scopes="$(jq -r ".campaigns[$i].compromised_scopes[]?" "$IOCS_FILE")"
    if [ -n "$scopes" ]; then
      while IFS= read -r scope; do
        [ -z "$scope" ] && continue
        local hits
        hits="$(find "${find_roots[@]}" -type d -path "*/node_modules/$scope" 2>/dev/null | head -20)"
        if [ -n "$hits" ]; then
          # For each installed scope, list versions.
          while IFS= read -r dir; do
            for pkg in "$dir"/*/package.json; do
              [ ! -f "$pkg" ] && continue
              local name ver optdeps
              name="$(jq -r '.name // empty' "$pkg" 2>/dev/null)"
              ver="$(jq -r '.version // empty' "$pkg" 2>/dev/null)"
              optdeps="$(jq -c '.optionalDependencies // {}' "$pkg" 2>/dev/null)"
              local install_time
              install_time="$(stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' "$pkg" 2>/dev/null || stat -c '%y' "$pkg" 2>/dev/null | cut -d. -f1)"
              AT_RISK="${AT_RISK}- \`${name}@${ver}\` (installed ${install_time}) — \`${pkg}\`
"
              # Check optionalDependencies against this campaign's IOC prefixes.
              local opt_iocs
              opt_iocs="$(jq -r ".campaigns[$i].optional_dependency_iocs[]?" "$IOCS_FILE")"
              while IFS= read -r needle; do
                [ -z "$needle" ] && continue
                if echo "$optdeps" | grep -qF "$needle"; then
                  row "$cname" "optionalDeps IOC ($needle) in $name@$ver" "FAIL" "$pkg"
                  PHASE_B_FAILS=$((PHASE_B_FAILS+1))
                fi
              done <<< "$opt_iocs"
            done
          done <<< "$hits"
          row "$cname" "scope $scope installed (review versions vs disclosure)" "FAIL" "$(echo "$hits" | wc -l | tr -d ' ') location(s)"
          PHASE_B_FAILS=$((PHASE_B_FAILS+1))
        else
          row "$cname" "scope $scope not installed" "PASS" ""
        fi
      done <<< "$scopes"
    fi

    # B2: compromised unscoped packages.
    local pkgs
    pkgs="$(jq -r ".campaigns[$i].compromised_packages[]?" "$IOCS_FILE")"
    while IFS= read -r p; do
      [ -z "$p" ] && continue
      local hits
      hits="$(find "${find_roots[@]}" -type d -path "*/node_modules/$p" 2>/dev/null | head -5)"
      if [ -n "$hits" ]; then
        while IFS= read -r dir; do
          local pkg="$dir/package.json"
          [ ! -f "$pkg" ] && continue
          local ver install_time
          ver="$(jq -r '.version // empty' "$pkg" 2>/dev/null)"
          install_time="$(stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' "$pkg" 2>/dev/null || stat -c '%y' "$pkg" 2>/dev/null | cut -d. -f1)"
          AT_RISK="${AT_RISK}- \`${p}@${ver}\` (installed ${install_time}) — \`${pkg}\`
"
        done <<< "$hits"
        row "$cname" "package $p installed (review versions vs disclosure)" "FAIL" ""
        PHASE_B_FAILS=$((PHASE_B_FAILS+1))
      else
        row "$cname" "package $p not installed" "PASS" ""
      fi
    done <<< "$pkgs"

    # B3: payload filenames anywhere under roots.
    local payloads
    payloads="$(jq -r ".campaigns[$i].payload_files[]?" "$IOCS_FILE")"
    while IFS= read -r fname; do
      [ -z "$fname" ] && continue
      local hits
      hits="$(find "${find_roots[@]}" -type f -name "$fname" -not -path "*/Library/Caches/*" 2>/dev/null | head -3)"
      if [ -n "$hits" ]; then
        row "$cname" "payload filename $fname found" "FAIL" "$(echo "$hits" | head -1)"
        PHASE_B_FAILS=$((PHASE_B_FAILS+1))
        # If we have a hash for this filename, verify.
        local expected_hash
        expected_hash="$(jq -r ".campaigns[$i].payload_hashes_sha256.\"$fname\" // empty" "$IOCS_FILE")"
        if [ -n "$expected_hash" ] && command -v shasum >/dev/null 2>&1; then
          while IFS= read -r f; do
            local got
            got="$(shasum -a 256 "$f" 2>/dev/null | awk '{print $1}')"
            if [ "$got" = "$expected_hash" ]; then
              row "$cname" "payload SHA256 match on $f" "FAIL" "$got"
              PHASE_B_FAILS=$((PHASE_B_FAILS+1))
            fi
          done <<< "$hits"
        fi
      else
        row "$cname" "payload filename $fname absent" "PASS" ""
      fi
    done <<< "$payloads"

    # B4: string IOCs — grep through lockfiles + small JSON/JS files.
    local strings
    strings="$(jq -r ".campaigns[$i].string_iocs[]?" "$IOCS_FILE")"
    while IFS= read -r needle; do
      [ -z "$needle" ] && continue
      local hits
      hits="$(grep -rIlF "$needle" "${find_roots[@]}" \
        --include='package.json' --include='package-lock.json' \
        --include='pnpm-lock.yaml' --include='yarn.lock' \
        --include='bun.lock' --include='bun.lockb' \
        2>/dev/null | head -3)"
      if [ -n "$hits" ]; then
        row "$cname" "string IOC \`$needle\` in lockfile" "FAIL" "$(echo "$hits" | head -1)"
        PHASE_B_FAILS=$((PHASE_B_FAILS+1))
      else
        row "$cname" "string IOC \`$needle\` absent in lockfiles" "PASS" ""
      fi
    done <<< "$strings"
  done
}

# ───────────────────────────────────────────────────────────────
# PHASE C — Time-window match
# ───────────────────────────────────────────────────────────────
phase_c() {
  local n_campaigns
  n_campaigns="$(jq '.campaigns | length' "$IOCS_FILE")"

  local find_roots=()
  for r in "${ROOTS[@]}"; do
    [ -d "$r" ] && find_roots+=("$r")
  done
  if [ "${#find_roots[@]}" -eq 0 ]; then
    row "ALL" "Phase C (no valid roots)" "skipped" ""
    return
  fi

  for i in $(seq 0 $((n_campaigns-1))); do
    local cid cname
    cid="$(jq -r ".campaigns[$i].id" "$IOCS_FILE")"
    cname="$(jq -r ".campaigns[$i].name" "$IOCS_FILE")"

    local n_windows
    n_windows="$(jq ".campaigns[$i].attack_windows_utc | length" "$IOCS_FILE")"
    if [ "$n_windows" -eq 0 ]; then
      row "$cname" "time-window (no window declared)" "skipped" ""
      continue
    fi

    for w in $(seq 0 $((n_windows-1))); do
      local start end
      start="$(jq -r ".campaigns[$i].attack_windows_utc[$w].start" "$IOCS_FILE")"
      end="$(jq -r ".campaigns[$i].attack_windows_utc[$w].end" "$IOCS_FILE")"

      # GNU find supports -newermt; BSD find on macOS does too.
      # Convert UTC ISO to local for find. macOS `date -j -f` handles this.
      local hits
      hits="$(find "${find_roots[@]}" -type f -path '*/node_modules/*' \
        -newermt "$start" ! -newermt "$end" 2>/dev/null | head -5)"
      if [ -n "$hits" ]; then
        row "$cname" "files written in attack window $start → $end" "FAIL" "$(echo "$hits" | wc -l | tr -d ' ') file(s)"
        PHASE_C_FAILS=$((PHASE_C_FAILS+1))
      else
        row "$cname" "no files written in window $start → $end" "PASS" ""
      fi
    done
  done
}

phase_a
phase_b
phase_c

# Verdict.
if [ "$FAIL_COUNT" -gt 0 ]; then
  VERDICT="POTENTIALLY COMPROMISED"
else
  VERDICT="CLEAN"
fi

# Emit report.
cat <<EOF
# Supply-chain audit — ${HOSTNAME_VAL} — ${TIMESTAMP}

IOC pack version: ${IOC_VERSION}
Roots scanned: ${ROOTS[*]}
OS: ${OS}

${STALENESS_WARNING}

## Verdict: ${VERDICT}

## IOC checklist
| Campaign | Check | Result |
|----------|-------|--------|
${CHECKLIST}

## At-risk packages
$([ -n "$AT_RISK" ] && echo "$AT_RISK" || echo "_None installed under scanned roots._")

## Phase summary
- Phase A (persistence): ${PHASE_A_FAILS} fail(s)
- Phase B (code & cache): ${PHASE_B_FAILS} fail(s)
- Phase C (time window): ${PHASE_C_FAILS} fail(s)
- Total: ${PASS_COUNT} PASS / ${FAIL_COUNT} FAIL / ${SKIP_COUNT} skipped

EOF
