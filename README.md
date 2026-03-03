# lazydocker binary mirror

This repository automatically mirrors the latest Linux `lazydocker` binary from:

- `https://github.com/jesseduffield/lazydocker`

The workflow runs every day and also supports manual run via **Actions -> Update lazydocker binary -> Run workflow**.

## Output files

After each successful update, the repository contains:

- `binaries/lazydocker.vX.Y.Z` (unpacked binary for a specific version)
- `binaries/lazydocker.vX.Y.Z.md5` (MD5 hash of that versioned binary)
- `binaries/lazydocker.latest` (unpacked binary for the newest version)
- `binaries/lazydocker.latest.md5` (MD5 hash of the `latest` binary)

## Notes

- The updater downloads the `Linux_x86_64` release archive.
- The workflow commits only when files in `binaries/` changed.
