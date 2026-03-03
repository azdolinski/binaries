# binary mirror automation

This repository automatically downloads, unpacks/builds, and stores Linux binaries from upstream projects.

Currently supported projects:

- `lazydocker` from `https://github.com/jesseduffield/lazydocker`
- `htop` from `https://github.com/htop-dev/htop`

## Purpose

The goal is to keep up-to-date, ready-to-use binaries in this repository without manual download, extraction, or build steps.

## Output files

After each successful update for a tool named `toolname`, the repository contains:

- `binaries/toolname.vX.Y.Z`
- `binaries/toolname.vX.Y.Z.md5`
- `binaries/toolname.latest`
- `binaries/toolname.latest.md5`

Examples:

- `binaries/lazydocker.v0.24.4`
- `binaries/htop.v3.4.1`

## Automation

Each updater workflow runs every day at 03:00 UTC and also supports manual run via GitHub Actions.

Current workflows:

- `Update lazydocker binary`
- `Update htop binary`

## Notes

- `lazydocker` is downloaded from release assets and stored as an unpacked executable.
- `htop` is downloaded from release source archive, built in CI, and then stored as an executable.
- Each workflow commits only when files in `binaries/` changed.
- This structure is designed to be extended with more tools in future.
