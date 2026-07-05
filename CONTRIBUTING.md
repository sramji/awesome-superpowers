# Contributing

Thanks for helping make awesome-superpowers better.

## Running the tests

All three suites are plain bash and run from a clone with no setup:

```bash
bash tests/validate.sh            # cross-refs, upstream manifest, front-matter, hygiene
bash tests/test-install.sh        # installer behavior in throwaway dirs
bash tests/test-branch-detection.sh
```

CI runs the same three on `ubuntu-latest` for every push and PR.

## Platform support

Developed and tested on **WSL2** (Ubuntu userland on Windows 11). CI runs on
GitHub's `ubuntu-latest`. macOS, native Linux, and other platforms are
**untested** — the suites assume GNU coreutils / bash (e.g. `xargs -r`, some
`grep` behaviors), so BSD/macOS users may hit differences. **PRs adding platform
coverage are very welcome.**

## Notes

- The kit skills are `SKILL.md` files under `skills/`. Keep each directory name
  equal to its front-matter `name:` — `tests/validate.sh` enforces this.
- Don't hardcode machine-specific absolute home paths (use `$HOME` or `~`
  instead) in shipped files; the hygiene check rejects them. (This very line
  avoids such hardcoded paths for exactly that reason.)
