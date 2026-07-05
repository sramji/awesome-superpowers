# Security Policy

## What `install.sh` does

`install.sh` only:

- reads the kit files in this repository, and
- writes skill directories into `<your-project>/.claude/skills/` — and, on
  `--force`, first moves any pre-existing same-named skill into a sibling
  `<your-project>/.claude/skills-backup-<timestamp>/`.

It performs no network requests and no privileged (`sudo`) operations. It is
short — read it before you run it.

## Reporting a vulnerability

Please use GitHub's private vulnerability reporting on this repository
(**Security** tab → **Report a vulnerability**). We aim to acknowledge within a
week.
