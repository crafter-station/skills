#!/usr/bin/env bash
# supply-chain-audit / scan.sh
# Read-only scanner. Emits a markdown report to stdout.
# Usage: scan.sh [project_root ...]
# Defaults: $HOME if no roots given.
# Env: SUPPLY_CHAIN_IOCS overrides the IOC pack path (testing only).

set -u
# Deliberately NOT set -e — a missing tool on one phase shouldn't abort the others.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
IOCS_FILE="${SUPPLY_CHAIN_IOCS:-$SKILL_DIR/iocs.json}"

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
# Only FAIL rows count toward POTENTIALLY COMPROMISED — those are the unambiguous
# signals (persistence artifact present, payload file found, malicious hash match,
# string IOC in lockfile, optionalDeps git-ref smuggle, repo-artifact hash match,
# forged-author commit, Phase C time-window hit).
# REVIEW rows are inventory (you have a copy of a package whose scope was attacked,
# but install timestamp is outside the attack window) — they need a human glance,
# not an alarm.
FAIL_COUNT=0
PASS_COUNT=0
SKIP_COUNT=0
REVIEW_COUNT=0

# Buffers for sections.
CHECKLIST=""
AT_RISK=""
PHASE_A_FAILS=0
PHASE_B_FAILS=0
PHASE_C_FAILS=0
PHASE_D_FAILS=0
PHASE_B_REVIEWS=0

# Prefer GNU `sha256sum` (Linux default), fall back to `shasum -a 256` (macOS / Perl).
HASHER=""
if command -v sha256sum >/dev/null 2>&1; then
  HASHER="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
  HASHER="shasum -a 256"
fi

row() {
  # row campaign check result [evidence]
  local campaign="$1" check="$2" result="$3" evidence="${4:-}"
  case "$result" in
    PASS) PASS_COUNT=$((PASS_COUNT+1)) ;;
    FAIL) FAIL_COUNT=$((FAIL_COUNT+1)) ;;
    REVIEW) REVIEW_COUNT=$((REVIEW_COUNT+1)) ;;
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

to_local_ts() {
  # ISO-8601 UTC (2026-08-04T09:00:00Z) → "YYYY-MM-DD HH:MM:SS" local time.
  # BSD find's -newermt cannot parse the T/Z form (it errors, which 2>/dev/null
  # used to swallow — turning every Phase C row into a vacuous PASS on macOS).
  # Empty output = conversion failed; callers must skip, not pass.
  local iso="$1" epoch
  epoch="$(date -j -u -f '%Y-%m-%dT%H:%M:%SZ' "$iso" +%s 2>/dev/null || date -d "$iso" +%s 2>/dev/null || echo "")"
  if [ -n "$epoch" ]; then
    date -r "$epoch" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -d "@$epoch" '+%Y-%m-%d %H:%M:%S' 2>/dev/null
  fi
}

# Valid roots, computed once.
VALID_ROOTS=()
for r in "${ROOTS[@]}"; do
  [ -d "$r" ] && VALID_ROOTS+=("$r")
done

# ───────────────────────────────────────────────────────────────
# Shared inventories — one filesystem walk per artifact class,
# instead of one walk per IOC per campaign. Phases B and D filter
# these lists in-memory.
# ───────────────────────────────────────────────────────────────
WORKDIR="$(mktemp -d /tmp/supply-chain-audit-XXXXXX)"
trap 'rm -rf "$WORKDIR"' EXIT

build_inventories() {
  : > "$WORKDIR/nm_dirs.txt"
  : > "$WORKDIR/payload_hits.txt"
  : > "$WORKDIR/string_hits.txt"
  : > "$WORKDIR/artifact_files.txt"
  : > "$WORKDIR/git_dirs.txt"
  [ "${#VALID_ROOTS[@]}" -eq 0 ] && return

  # 1. node_modules dirs matching any compromised scope/package name (all campaigns).
  local dir_conds=()
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    [ "${#dir_conds[@]}" -gt 0 ] && dir_conds+=(-o)
    dir_conds+=(-path "*/node_modules/$name")
  done < <(jq -r '[.campaigns[].compromised_scopes[]?, .campaigns[].compromised_packages[]?] | unique | .[]' "$IOCS_FILE")
  if [ "${#dir_conds[@]}" -gt 0 ]; then
    find "${VALID_ROOTS[@]}" -type d \( "${dir_conds[@]}" \) 2>/dev/null > "$WORKDIR/nm_dirs.txt"
  fi

  # 2. payload filename hits (all campaigns).
  local file_conds=()
  while IFS= read -r fname; do
    [ -z "$fname" ] && continue
    [ "${#file_conds[@]}" -gt 0 ] && file_conds+=(-o)
    file_conds+=(-name "$fname")
  done < <(jq -r '[.campaigns[].payload_files[]?] | unique | .[]' "$IOCS_FILE")
  if [ "${#file_conds[@]}" -gt 0 ]; then
    find "${VALID_ROOTS[@]}" -type f \( "${file_conds[@]}" \) -not -path "*/Library/Caches/*" 2>/dev/null > "$WORKDIR/payload_hits.txt"
  fi

  # 3. string IOCs — one content pass over lockfiles/manifests with every needle,
  #    then per-needle attribution against the (tiny) hit set.
  local grep_args=()
  while IFS= read -r needle; do
    [ -z "$needle" ] && continue
    grep_args+=(-e "$needle")
  done < <(jq -r '[.campaigns[].string_iocs[]?] | unique | .[]' "$IOCS_FILE")
  if [ "${#grep_args[@]}" -gt 0 ]; then
    find "${VALID_ROOTS[@]}" -type f \
      \( -name 'package.json' -o -name 'package-lock.json' \
         -o -name 'pnpm-lock.yaml' -o -name 'yarn.lock' \
         -o -name 'bun.lock' -o -name 'bun.lockb' \) \
      -print0 2>/dev/null > "$WORKDIR/lockfiles.z"
    if [ -s "$WORKDIR/lockfiles.z" ]; then
      xargs -0 grep -IlF "${grep_args[@]}" < "$WORKDIR/lockfiles.z" 2>/dev/null | sort -u > "$WORKDIR/string_hits.txt"
    fi
  fi

  # 4. repo-level artifact files (all campaigns' repo_artifact_hashes keys).
  local art_conds=()
  while IFS= read -r rel; do
    [ -z "$rel" ] && continue
    [ "${#art_conds[@]}" -gt 0 ] && art_conds+=(-o)
    art_conds+=(-path "*/$rel")
  done < <(jq -r '[.campaigns[] | (.repo_artifact_hashes // {}) | keys[]] | unique | .[]' "$IOCS_FILE")
  if [ "${#art_conds[@]}" -gt 0 ]; then
    find "${VALID_ROOTS[@]}" -type f \( "${art_conds[@]}" \) 2>/dev/null > "$WORKDIR/artifact_files.txt"
  fi

  # 5. git repos (for forged-commit checks).
  if jq -e '[.campaigns[].forged_commit_authors[]?] | length > 0' "$IOCS_FILE" >/dev/null 2>&1; then
    find "${VALID_ROOTS[@]}" -type d -name .git 2>/dev/null > "$WORKDIR/git_dirs.txt"
  fi
}

filter_suffix() {
  # filter_suffix <inventory-file> <suffix> — print lines ending in /<suffix>.
  local file="$1" suffix="$2" line
  while IFS= read -r line; do
    case "$line" in */"$suffix") printf '%s\n' "$line" ;; esac
  done < "$file"
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

  if [ "${#VALID_ROOTS[@]}" -eq 0 ]; then
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
        hits="$(filter_suffix "$WORKDIR/nm_dirs.txt" "node_modules/$scope" | head -20)"
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
          # Inventory row — REVIEW, not FAIL. Phase C catches actual exposure.
          row "$cname" "scope $scope installed (inventory — cross-check Phase C)" "REVIEW" "$(echo "$hits" | wc -l | tr -d ' ') location(s)"
          PHASE_B_REVIEWS=$((PHASE_B_REVIEWS+1))
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
      hits="$(filter_suffix "$WORKDIR/nm_dirs.txt" "node_modules/$p" | head -5)"
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
        # Inventory row — REVIEW, not FAIL.
        row "$cname" "package $p installed (inventory — cross-check Phase C)" "REVIEW" ""
        PHASE_B_REVIEWS=$((PHASE_B_REVIEWS+1))
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
      hits="$(filter_suffix "$WORKDIR/payload_hits.txt" "$fname" | head -3)"
      if [ -n "$hits" ]; then
        row "$cname" "payload filename $fname found" "FAIL" "$(echo "$hits" | head -1)"
        PHASE_B_FAILS=$((PHASE_B_FAILS+1))
        # If we have a hash for this filename, verify.
        local expected_hash
        expected_hash="$(jq -r ".campaigns[$i].payload_hashes_sha256.\"$fname\" // empty" "$IOCS_FILE")"
        if [ -n "$expected_hash" ] && [ -n "$HASHER" ]; then
          while IFS= read -r f; do
            local got
            got="$($HASHER "$f" 2>/dev/null | awk '{print $1}')"
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

    # B4: string IOCs — attribute the shared grep pass per needle.
    local strings
    strings="$(jq -r ".campaigns[$i].string_iocs[]?" "$IOCS_FILE")"
    while IFS= read -r needle; do
      [ -z "$needle" ] && continue
      local hits="" f
      while IFS= read -r f; do
        [ -z "$f" ] && continue
        if grep -qIF -- "$needle" "$f" 2>/dev/null; then
          hits="${hits}${f}
"
        fi
      done < "$WORKDIR/string_hits.txt"
      hits="$(printf '%s' "$hits" | head -3)"
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

  if [ "${#VALID_ROOTS[@]}" -eq 0 ]; then
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
      local start end start_local end_local
      start="$(jq -r ".campaigns[$i].attack_windows_utc[$w].start" "$IOCS_FILE")"
      end="$(jq -r ".campaigns[$i].attack_windows_utc[$w].end" "$IOCS_FILE")"
      start_local="$(to_local_ts "$start")"
      end_local="$(to_local_ts "$end")"
      if [ -z "$start_local" ] || [ -z "$end_local" ]; then
        row "$cname" "time-window $start → $end" "skipped" "cannot convert timestamp on this platform"
        continue
      fi

      # A find error must surface as skipped, never as a silent PASS.
      local hits
      hits="$(find "${VALID_ROOTS[@]}" -type f -path '*/node_modules/*' \
        -newermt "$start_local" ! -newermt "$end_local" 2>"$WORKDIR/find_err.txt" | head -5)"
      if [ -n "$hits" ]; then
        row "$cname" "files written in attack window $start → $end" "FAIL" "$(echo "$hits" | wc -l | tr -d ' ') file(s)"
        PHASE_C_FAILS=$((PHASE_C_FAILS+1))
      elif grep -qim1 "can't parse\|invalid\|illegal" "$WORKDIR/find_err.txt" 2>/dev/null; then
        # Parse/usage errors mean the window was never evaluated. Permission
        # noise is fine; a broken predicate masquerading as PASS is not.
        row "$cname" "time-window $start → $end" "skipped" "$(grep -im1 "can't parse\|invalid\|illegal" "$WORKDIR/find_err.txt")"
      else
        row "$cname" "no files written in window $start → $end" "PASS" ""
      fi
    done
  done
}

# ───────────────────────────────────────────────────────────────
# PHASE D — Repo-level artifacts & git history
# ───────────────────────────────────────────────────────────────
phase_d() {
  local n_campaigns
  n_campaigns="$(jq '.campaigns | length' "$IOCS_FILE")"

  if [ "${#VALID_ROOTS[@]}" -eq 0 ]; then
    row "ALL" "Phase D (no valid roots)" "skipped" ""
    return
  fi

  for i in $(seq 0 $((n_campaigns-1))); do
    local cname
    cname="$(jq -r ".campaigns[$i].name" "$IOCS_FILE")"

    # D1: repo-level artifact hashes. Filenames like .vscode/tasks.json are too
    # generic for a presence check — only an exact hash match is a FAIL.
    local n_art
    n_art="$(jq ".campaigns[$i].repo_artifact_hashes // {} | length" "$IOCS_FILE")"
    if [ "$n_art" -eq 0 ]; then
      row "$cname" "repo-artifact hashes (none declared)" "skipped" ""
    elif [ -z "$HASHER" ]; then
      row "$cname" "repo-artifact hashes" "skipped" "no sha256 tool available"
    else
      while IFS= read -r rel; do
        [ -z "$rel" ] && continue
        local bad="" f got h
        while IFS= read -r f; do
          [ -z "$f" ] && continue
          got="$($HASHER "$f" 2>/dev/null | awk '{print $1}')"
          while IFS= read -r h; do
            [ -z "$h" ] && continue
            if [ "$got" = "$h" ]; then
              bad="$f"
            fi
          done < <(jq -r --argjson i "$i" --arg k "$rel" '.campaigns[$i].repo_artifact_hashes[$k] | if type == "string" then [.] else . end | .[]' "$IOCS_FILE")
          [ -n "$bad" ] && break
        done < <(filter_suffix "$WORKDIR/artifact_files.txt" "$rel")
        if [ -n "$bad" ]; then
          row "$cname" "repo artifact $rel hash match" "FAIL" "$bad"
          PHASE_D_FAILS=$((PHASE_D_FAILS+1))
        else
          row "$cname" "repo artifact $rel no hash match" "PASS" ""
        fi
      done < <(jq -r ".campaigns[$i].repo_artifact_hashes // {} | keys[]" "$IOCS_FILE")
    fi

    # D2: forged commit authors in any git repo under the roots.
    local authors
    authors="$(jq -r ".campaigns[$i].forged_commit_authors[]?" "$IOCS_FILE")"
    if [ -z "$authors" ]; then
      row "$cname" "forged-commit authors (none declared)" "skipped" ""
    elif ! command -v git >/dev/null 2>&1; then
      row "$cname" "forged-commit authors" "skipped" "git not available"
    else
      while IFS= read -r author; do
        [ -z "$author" ] && continue
        local count=0 evid="" gitdir repo hit
        while IFS= read -r gitdir; do
          [ -z "$gitdir" ] && continue
          repo="${gitdir%/.git}"
          hit="$(git -C "$repo" log --all --format=%h -1 --author="$author" 2>/dev/null)"
          if [ -n "$hit" ]; then
            count=$((count+1))
            [ "$count" -le 3 ] && evid="${evid}${repo}@${hit} "
          fi
        done < "$WORKDIR/git_dirs.txt"
        if [ "$count" -gt 0 ]; then
          row "$cname" "commits authored $author found" "FAIL" "$count repo(s): $evid"
          PHASE_D_FAILS=$((PHASE_D_FAILS+1))
        else
          row "$cname" "no commits authored $author" "PASS" ""
        fi
      done <<< "$authors"
    fi
  done
}

build_inventories
phase_a
phase_b
phase_c
phase_d

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

## Inventory — packages from compromised scopes (REVIEW, not FAIL)
These are installed copies of packages whose scope was attacked at some point. They become a real problem only if Phase C shows file writes during the attack window, or if the installed version exactly matches a disclosed malicious version. Cross-check before alarming.

$([ -n "$AT_RISK" ] && echo "$AT_RISK" || echo "_None installed under scanned roots._")

## Phase summary
- Phase A (persistence): ${PHASE_A_FAILS} fail(s)
- Phase B (code & cache): ${PHASE_B_FAILS} fail(s), ${PHASE_B_REVIEWS} review(s)
- Phase C (time window): ${PHASE_C_FAILS} fail(s) — authoritative exposure signal
- Phase D (repo artifacts & git history): ${PHASE_D_FAILS} fail(s)
- Total: ${PASS_COUNT} PASS / ${FAIL_COUNT} FAIL / ${REVIEW_COUNT} REVIEW / ${SKIP_COUNT} skipped

EOF
