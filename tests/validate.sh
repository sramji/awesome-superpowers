#!/usr/bin/env bash
set -euo pipefail

# KIT defaults to the repo root (parent of this tests/ dir), so a fresh clone
# runs green with no setup. An explicit KIT=... still overrides.
KIT="${KIT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

UPSTREAM_ALLOWED='brainstorming|writing-plans|executing-plans|requesting-code-review|receiving-code-review|finishing-a-development-branch|using-git-worktrees|code-reviewer|subagent-driven-development'
# awesome-* tokens legitimately referenced inside skill bodies, plus the repo name.
KIT_AWESOME='awesome-brainstorming|awesome-writing-plans|awesome-superpowers'

fail() { echo "VALIDATE FAIL: $*" >&2; exit 1; }

scan_paths() {
  # Shipped, human-authored content. Prune docs/design (not published), VCS, and build scratch.
  find "$KIT" -type f \( -name '*.md' -o -name 'VERSION' -o -name 'install.sh' \) \
    -not -path '*/docs/design/*' -not -path '*/.git/*' -not -path '*/.superpowers/*'
}

# --- Check 1: generic hygiene (PII-free, safe to ship) ---
# Forbids (a) machine-specific absolute paths and (b) a small NAME-FREE cos
# coupling denylist, in shipped files. No personal names — pattern-based only,
# safe to publish. ($HOME/~ are fine; only literal /home/<u>, /root/, /mnt/ etc.)
# This is the STANDING guard that remains in CI after the private build dir (and
# its personal-token gate) are deleted post-publish — so it must catch machine
# paths without a trailing slash and the durable coupling tokens.
check_hygiene() {
  local hits
  hits=$(scan_paths | xargs -r grep -rniE \
    '/home/[^/[:space:]]+|/Users/[^/[:space:]]+|/root/|/srv/|/mnt/|data_root|projects/cos|promises\.yaml' \
    2>/dev/null || true)
  if [[ -n "$hits" ]]; then
    echo "$hits" >&2
    fail "hygiene: machine-specific path or cos coupling token in shipped content"
  fi
  echo "OK   check 1: no machine paths or coupling tokens"
}

# --- Check 2: cross-reference integrity ---
check_xref() {
  local bad
  bad=$(grep -rhoE 'superpowers:[a-z-]+' "$KIT/skills" 2>/dev/null \
        | sed 's/superpowers://' | sort -u \
        | grep -vE "^($UPSTREAM_ALLOWED)$" || true)
  [[ -z "$bad" ]] || fail "unknown superpowers skill referenced: $bad"
  local badint
  badint=$(grep -rhoE 'awesome-[a-z-]+' "$KIT/skills" 2>/dev/null | sort -u \
           | grep -vE "^($KIT_AWESOME)$" || true)
  [[ -z "$badint" ]] || { echo "$badint" >&2; fail "unknown awesome-* skill referenced (typo?)"; }
  if [[ -f "$KIT/skills/finishing-with-review/SKILL.md" ]]; then
    grep -q 'end-of-session-reflection' "$KIT/skills/finishing-with-review/SKILL.md" \
      || fail "finishing-with-review: exact 'end-of-session-reflection' handoff missing (typo?)"
  fi
  local excluded
  excluded=$(grep -rnE 'worktree-pr-merge|cos-development|capture-booking' "$KIT/skills" 2>/dev/null || true)
  [[ -z "$excluded" ]] || { echo "$excluded" >&2; fail "reference to excluded skill"; }
  echo "OK   check 2: cross-references resolve"
}

# --- Check 3: upstream-dependency manifest ---
check_manifest() {
  local used
  used=$(grep -rhoE 'superpowers:[a-z-]+' "$KIT/skills" 2>/dev/null \
        | sed 's/superpowers://' | sort -u || true)
  local f
  for f in $used; do
    grep -qE "superpowers:$f([^a-z-]|$)" "$KIT/README.md" 2>/dev/null \
      || fail "upstream skill '$f' used but not declared as superpowers:$f in README"
  done
  echo "OK   check 3: upstream surface declared"
}

# --- Check 4: front-matter validity ---
check_frontmatter() {
  shopt -s nullglob
  local dirs=( "$KIT"/skills/*/ )
  [[ ${#dirs[@]} -gt 0 ]] || fail "no skills present in $KIT/skills"
  local d name
  for d in "${dirs[@]}"; do
    [[ -f "$d/SKILL.md" ]] || fail "missing SKILL.md in $d"
    head -1 "$d/SKILL.md" | grep -q '^---$' || fail "no front-matter in $d/SKILL.md"
    name=$(awk '/^name:/{print $2; exit}' "$d/SKILL.md")
    [[ -n "$name" ]] || fail "no name: in $d/SKILL.md"
    grep -q '^description:' "$d/SKILL.md" || fail "no description: in $d/SKILL.md"
    [[ "$(basename "$d")" == "$name" ]] || fail "dir/name mismatch: $(basename "$d") vs $name"
  done
  echo "OK   check 4: front-matter valid"
}

case "${1:-all}" in
  hygiene) check_hygiene ;;
  all) check_hygiene; check_xref; check_manifest; check_frontmatter; echo "ALL CHECKS PASS" ;;
  *) fail "unknown mode: $1" ;;
esac
