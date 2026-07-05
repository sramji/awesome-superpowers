---
name: autonomous-chunk-execution
description: Use when a large cross-cutting task (code review remediation, migration, refactor) has 5+ independent items spanning multiple files — breaks work into autonomous sequential chunks with shared tracking
---

# Autonomous Chunk Execution

## Overview

Break large multi-file projects into independently reviewable chunks, each executed as a separate worktree/PR. A YAML tracker on the main branch provides cross-session state; an execution plan in the repo provides detailed per-chunk instructions; a prompt template bootstraps each worker session.

## When to Use

- Code review remediation (many fixes across many files)
- Large migrations or refactors that touch 5+ files
- Any project with 5+ independent items that must be done sequentially
- Work that may span multiple sessions or be delegated to worker agents

## The Pattern

### Three artifacts, all in the repo:

1. **YAML tracker** — per-item and per-chunk status, lives on main
2. **Execution plan** — detailed per-chunk instructions with file paths, verification steps
3. **Prompt template** — paste into each worker session to bootstrap autonomously

### Tracker structure

```yaml
review: <project-name>
started: <date>
chunks:
  chunk-name:
    branch: <prefix>/chunk-name
    status: TODO  # TODO | IN_PROGRESS | DONE
    pr: null
    items: [ITEM1, ITEM2]
items:
  ITEM1: {status: TODO, chunk: chunk-name, desc: "what to fix"}
```

`<prefix>` = your project's branch-naming convention.

### Prompt template

```
Read <tracker-path> to find the next TODO chunk.
Read <plan-path> for chunk details.

Execute the next TODO chunk:
1. Create an isolated worktree via `superpowers:using-git-worktrees`
2. Work each item, running tests after each fix
3. Finish via `finishing-with-review` (review-gated), then PR/merge per its options
4. Update tracker on main
```

## Chunking Strategy

Order chunks by **dependency**, not priority:

1. Files shared across chunks force sequential execution
2. Put highest-risk changes first (fail fast)
3. Put the largest refactor last (minimize merge conflicts)
4. Group deletions together (low risk, easy to review)
5. Each chunk must leave tests passing

## Infrastructure Requirements

- **Tracker file must be writable on main** — ensure your repo's main-branch protection allows direct commits for tracker updates, or use a dedicated state branch
- **Plan must be committed to the repo** — session-local locations are invisible to other sessions and worker agents
- **Each chunk is a separate branch/PR** — independently reviewable and revertable

## Context Budget (observed)

| Chunk type | Context usage (illustrative — one model/codebase) |
|------------|---------------------------------------------------|
| Deletions, dead code cleanup | ~10% |
| Small targeted fixes (5-8 files) | ~15-20% |
| Large refactor (extract helpers, move code) | ~60-80% |

Simple chunks can be batched in one session. Large refactors need their own session.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Plan kept only in a session-local location | Commit it to the repo so other sessions/workers can read it (session-local dirs are invisible across sessions) |
| Running chunks in parallel when they share files | Sequential only — merge conflicts are worse than waiting |
| No verification step per chunk | Always run full test suite before finishing each chunk |
| Starting the big refactor first | Do it last — every other chunk modifies the same files |
