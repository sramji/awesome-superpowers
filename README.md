# awesome-superpowers

Like many others, I find Jesse Vincent's Superpowers framework to be an excellent harness.  There are some specific things missing out-of-the-box for me: loops for improving brainstorming and planning, test-first thinking, and an enforced SDLC process through the skills.  Therefore, I've built awesome-superpowers, named for the skill wrappers in this project (awesome-brainstorming, awesome-writing-plans).

In my experience, this makes the goodput much higher, and allows Claude Code to run much longer autonomously, giving me more free time between mentoring/guidance moments.

[![ci](https://github.com/sramji/awesome-superpowers/actions/workflows/ci.yml/badge.svg)](https://github.com/sramji/awesome-superpowers/actions/workflows/ci.yml)

An SDLC layer on top of [Superpowers](https://github.com/obra/superpowers) for
Claude Code: rigor passes on your specs and plans, a mandatory code-review gate,
structured end-of-session reflection, and a pattern for large multi-chunk work.

> **Not an "Awesome List."** Despite the `awesome-` name, this is a *tool kit* of
> Claude Code skills, not a curated list of links.

These skills **extend** Superpowers; they do not replace it. All git, worktree,
and code-review mechanics are deferred to `superpowers:*` skills.

## Quick start (you already run Superpowers)

Clone the repo (or download a release archive and expand it), then point the
installer at your project:

```bash
git clone https://github.com/sramji/awesome-superpowers
bash awesome-superpowers/install.sh /path/to/your/project
```

Or, from inside your project directory:

```bash
bash /path/to/awesome-superpowers/install.sh
```

This copies the kit's five SDLC skills into `your-project/.claude/skills/`.
Restart Claude Code (or run `/skills`) to confirm they appear, then start work by
invoking the **awesome-brainstorming** skill.

## Don't have Superpowers yet?

Install it first; the kit's skills invoke it.

Recommended (official marketplace):

```
/plugin install superpowers@claude-plugins-official
```

Community marketplace alternative:

```
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

Then follow the Quick start above.

## Install paths

Both hit the same root `install.sh`:

1. **Clone.** Run `git clone`, then run `install.sh`.
2. **Release archive.** Download `awesome-superpowers-<version>.tar.gz` (or the
   GitHub "Source code" zip) from the Releases page, expand it, and run
   `install.sh` from the expanded directory.

### Verify your download (release archives)

```bash
sha256sum -c awesome-superpowers-<version>.tar.gz.sha256
```

Not needed for a `git clone`.

## Platform support

Developed and tested on **WSL2** (Ubuntu userland on Windows 11). CI additionally
runs the test suites on GitHub's `ubuntu-latest`. macOS, native Linux, and other
platforms are **untested**; **PRs adding platform coverage are welcome.** See
[`CONTRIBUTING.md`](CONTRIBUTING.md).

## Requirements

- **Claude Code** (these are `SKILL.md` files invoked by Claude Code's Skill tool).
- The **Superpowers plugin**, installed and enabled. The kit invokes these
  upstream skills: `superpowers:brainstorming`, `superpowers:writing-plans`,
  `superpowers:executing-plans`, `superpowers:requesting-code-review`,
  `superpowers:receiving-code-review`, `superpowers:code-reviewer`,
  `superpowers:subagent-driven-development`,
  `superpowers:finishing-a-development-branch`, `superpowers:using-git-worktrees`.
- Tested against the Superpowers version recorded in `VERSION`.

> **Scope:** Claude Code only. The reflection skill can *write to* an
> `AGENTS.md`/`GEMINI.md` if your repo has one, but the skills themselves do not
> self-execute on other agent platforms.

## What each skill does

- **awesome-brainstorming**: runs Superpowers brainstorming, then a single
  fresh-subagent rigor pass that strengthens the spec before you plan against it.
- **awesome-writing-plans**: runs Superpowers writing-plans, then up to three
  rounds of rigor that close failure-mode gaps before execution.
- **finishing-with-review**: gates every branch on a code review before it merges.
- **end-of-session-reflection**: harvests learnings and routes them to durable
  homes (created if absent) so knowledge survives between sessions.
- **autonomous-chunk-execution**: breaks large multi-file work into independently
  reviewable chunks with a shared tracker.

See [`docs/the-chain.md`](docs/the-chain.md) for how they chain together.

## Upgrading

Re-run the installer with `--force` to update kit-owned skills:

```bash
bash install.sh /path/to/your/project --force
```

If you already have a personal skill named like a kit skill, `--force` first
moves it to `your-project/.claude/skills-backup-<timestamp>/`; it is never
deleted.

## License

MIT. See [`LICENSE`](LICENSE). Attribution to Superpowers is in
[`NOTICE`](NOTICE).
