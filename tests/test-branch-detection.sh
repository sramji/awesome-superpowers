#!/usr/bin/env bash
set -euo pipefail
KIT="${KIT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SKILL="$KIT/skills/finishing-with-review/SKILL.md"

# Extract the marked bash block verbatim from the shipped skill (no DRY drift).
SNIP=$(awk '/# >>> base-branch-detection >>>/{f=1} f{print} /# <<< base-branch-detection <<</{f=0}' "$SKILL")
[[ -n "$SNIP" ]] || { echo "FAIL: detection block not found in skill" >&2; exit 1; }

# Runs the snippet in a subshell after $1 setup; prints BASE_REF= and BASE_SHA=
# lines plus any WARNING. The snippet's `set -e` runs inside the subshell only.
run_in() {
  local dir; dir=$(mktemp -d)
  ( cd "$dir"
    git init -q; git config user.email t@t; git config user.name t
    git commit -q --allow-empty -m init
    eval "$1"
    eval "$SNIP"
    echo "BASE_REF=${BASE_REF:-<none>}"
    echo "BASE_SHA=${BASE_SHA:-<empty>}"
  ) 2>&1
  rm -rf "$dir"
}

# A valid result = BASE_SHA is a real commit object (not empty, not the warning fallback
# when we expect a real base). assert_real_sha greps the echoed SHA and verifies length.
assert_sha_nonempty() {  # $1=output  $2=label
  echo "$1" | grep -qE 'BASE_SHA=[0-9a-f]{7,40}' || { echo "FAIL ($2): BASE_SHA empty/invalid"; echo "$1"; exit 1; }
}

echo "== Tier 3: no remote, local default 'master' =="
out=$(run_in 'git branch -m master; git checkout -q -b feature')
echo "$out" | grep -q 'BASE_REF=master' || { echo "FAIL: expected BASE_REF=master"; echo "$out"; exit 1; }
assert_sha_nonempty "$out" "tier3-master"; echo "OK"

echo "== Tier 3: no remote, local default 'main' =="
out=$(run_in 'git branch -m main; git checkout -q -b feature')
echo "$out" | grep -q 'BASE_REF=main' || { echo "FAIL: expected BASE_REF=main"; echo "$out"; exit 1; }
assert_sha_nonempty "$out" "tier3-main"; echo "OK"

echo "== Tier 1: remote with origin/HEAD, NO local main (the C1 repro) =="
# Build a bare remote with 'main', clone it, then delete the local main so only
# the remote-tracking ref remains — the exact shape that produced a garbage range.
out=$(run_in '
  git branch -m main
  remote=$(mktemp -d); git init -q --bare "$remote"
  git remote add origin "$remote"; git push -q origin main
  git remote set-head origin main
  git checkout -q -b feature
  git branch -q -D main')
echo "$out" | grep -q 'BASE_REF=origin/main' || { echo "FAIL: expected BASE_REF=origin/main"; echo "$out"; exit 1; }
echo "$out" | grep -qi 'WARNING' && { echo "FAIL: Tier 1 should not warn"; echo "$out"; exit 1; }
assert_sha_nonempty "$out" "tier1"; echo "OK"

echo "== Tier 2: no origin/HEAD, but an upstream is set =="
out=$(run_in '
  git branch -m main
  remote=$(mktemp -d); git init -q --bare "$remote"
  git remote add origin "$remote"; git push -q origin main
  git checkout -q -b feature
  git branch --set-upstream-to=origin/main feature >/dev/null
  git symbolic-ref -q --delete refs/remotes/origin/HEAD 2>/dev/null || true
  git branch -q -D main')
echo "$out" | grep -q 'BASE_REF=origin/main' || { echo "FAIL: expected BASE_REF=origin/main via upstream"; echo "$out"; exit 1; }
assert_sha_nonempty "$out" "tier2"; echo "OK"

echo "== Degrade: no remote, no main/master/trunk → warns, BASE_SHA=HEAD, no crash =="
# Rename the SOLE branch (don't just check out a new one — that would leave the
# initial main/master present and Tier 3 would resolve it, never reaching degrade).
out=$(run_in 'git branch -m odd-name')
echo "$out" | grep -qi 'WARNING' || { echo "FAIL: expected a warning"; echo "$out"; exit 1; }
assert_sha_nonempty "$out" "degrade"   # degrades to HEAD, still a real sha
echo "OK"

echo "ALL BRANCH-DETECTION TESTS PASS"
