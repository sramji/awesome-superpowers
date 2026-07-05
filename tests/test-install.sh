#!/usr/bin/env bash
set -euo pipefail
KIT="${KIT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
INSTALL="$KIT/install.sh"

t=$(mktemp -d)
trap 'rm -rf "$t"' EXIT

echo "== guard: no .claude/ → error, non-zero =="
if bash "$INSTALL" "$t/noclaude" >/dev/null 2>&1; then echo "FAIL: should have errored"; exit 1; fi
echo "OK"

echo "== fresh install lands 5 skills, each WITH its SKILL.md =="
mkdir -p "$t/proj/.claude"
bash "$INSTALL" "$t/proj" >/dev/null
n=$(find "$t/proj/.claude/skills" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l)
[[ "$n" -eq 5 ]] || { echo "FAIL: expected 5 SKILL.md, got $n"; exit 1; }
echo "OK"

echo "== re-run without --force refuses to clobber (non-zero) =="
if bash "$INSTALL" "$t/proj" >/dev/null 2>&1; then echo "FAIL: should refuse"; exit 1; fi
echo "OK"

echo "== re-run with --force actually REPLACES content (update path) =="
# Plant a sentinel in an installed skill; --force must overwrite it (replace, not merge/no-op).
echo "SENTINEL_SHOULD_BE_GONE" >> "$t/proj/.claude/skills/awesome-brainstorming/SKILL.md"
bash "$INSTALL" "$t/proj" --force >/dev/null
if grep -q SENTINEL_SHOULD_BE_GONE "$t/proj/.claude/skills/awesome-brainstorming/SKILL.md"; then
  echo "FAIL: --force did not replace skill content"; exit 1
fi
echo "OK"

echo "== --force backs up a user-authored same-named skill; leaves exactly 5 kit skills =="
mkdir -p "$t/proj3/.claude/skills/end-of-session-reflection"
printf 'USER_AUTHORED_CONTENT\n' > "$t/proj3/.claude/skills/end-of-session-reflection/SKILL.md"
bash "$INSTALL" "$t/proj3" --force >/dev/null
# (a) user content preserved in exactly one backup sibling
bak=$(grep -rl USER_AUTHORED_CONTENT "$t/proj3/.claude/"skills-backup-* 2>/dev/null | wc -l)
[[ "$bak" -eq 1 ]] || { echo "FAIL: user skill not backed up (found $bak)"; exit 1; }
# (b) exactly 5 kit skill dirs under skills/, no collision/leftover
n=$(find "$t/proj3/.claude/skills" -mindepth 1 -maxdepth 1 -type d | wc -l)
[[ "$n" -eq 5 ]] || { echo "FAIL: expected 5 skill dirs, got $n"; exit 1; }
# (c) the installed skill is the kit's, not the user's
if grep -q USER_AUTHORED_CONTENT "$t/proj3/.claude/skills/end-of-session-reflection/SKILL.md"; then
  echo "FAIL: kit skill did not overwrite user's"; exit 1
fi
echo "OK"

echo "ALL INSTALL TESTS PASS"
