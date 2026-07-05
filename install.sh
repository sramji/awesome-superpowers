#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS=(awesome-brainstorming awesome-writing-plans finishing-with-review
        end-of-session-reflection autonomous-chunk-execution)
UPSTREAM=(brainstorming writing-plans executing-plans requesting-code-review
          receiving-code-review code-reviewer subagent-driven-development
          finishing-a-development-branch using-git-worktrees)

FORCE=0; TARGET="$PWD"
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    -*) echo "unknown flag: $arg" >&2; exit 2 ;;
    *) TARGET="$arg" ;;
  esac
done

[[ -f "$HERE/VERSION" ]] && { echo "Installing $(head -1 "$HERE/VERSION")"; }

if [[ ! -d "$TARGET/.claude" ]]; then
  echo "ERROR: '$TARGET' is not a Claude Code project root (no .claude/ dir)." >&2
  echo "Run from your project, or pass its path: bash install.sh /path/to/project" >&2
  exit 1
fi

# Best-effort upstream preflight (warn, never fail). A false negative here is
# harmless — it does not block install.
if ! ls -d "$HOME"/.claude/plugins/*/superpowers* >/dev/null 2>&1 \
   && ! ls -d "$TARGET"/.claude/plugins/*/superpowers* >/dev/null 2>&1; then
  echo "NOTE: couldn't auto-detect the Superpowers plugin (harmless if you already have it)." >&2
  echo "      These skills invoke: ${UPSTREAM[*]}" >&2
  echo "      If you don't have Superpowers, install it or the chain stops mid-flow." >&2
fi

DEST="$TARGET/.claude/skills"
mkdir -p "$DEST"

# Conflict check first (no partial installs).
conflicts=()
for s in "${SKILLS[@]}"; do [[ -e "$DEST/$s" ]] && conflicts+=("$s"); done
if [[ ${#conflicts[@]} -gt 0 && $FORCE -ne 1 ]]; then
  echo "ERROR: these skills already exist in $DEST:" >&2
  printf '  - %s\n' "${conflicts[@]}" >&2
  echo "Re-run with --force to update them (existing versions are backed up first)." >&2
  exit 1
fi

# Under --force, back up any pre-existing skill dirs to a sibling of skills/.
# Claude Code scans only .claude/skills/*, so a skills-backup-* sibling is inert
# and cannot collide with the freshly installed skill names.
if [[ ${#conflicts[@]} -gt 0 && $FORCE -eq 1 ]]; then
  ts=$(date +%Y%m%d-%H%M%S)
  BACKUP="$TARGET/.claude/skills-backup-$ts"
  mkdir -p "$BACKUP"
  for s in "${conflicts[@]}"; do mv "$DEST/$s" "$BACKUP/$s"; done
  echo "Backed up ${#conflicts[@]} pre-existing skill(s) to $BACKUP"
fi

for s in "${SKILLS[@]}"; do
  rm -rf "$DEST/$s"
  cp -R "$HERE/skills/$s" "$DEST/$s"
done

echo
echo "Installed ${#SKILLS[@]} skills into $DEST:"
printf '  - %s\n' "${SKILLS[@]}"
echo
echo "Next: restart Claude Code (or run /skills) and confirm the awesome-* skills appear."
echo "Then start work by invoking the awesome-brainstorming skill."
