---
name: rebuild
description: Run the correct NixOS rebuild command for this flake
disable-model-invocation: true
---

Determine the right rebuild command based on $ARGUMENTS (or ask if ambiguous), then run it.

The flake lives at `~/erebus` and defines two hosts: `pc` and `asusLaptop`.
`nh` picks the one matching the current hostname, so neither command names a host.

## Available commands

| Alias | What it does |
|-------|-------------|
| `rebuild` | `nh os switch ~/erebus -- --impure` — local NixOS switch |
| `update` | `nh os switch ~/erebus --update -- --impure` — update flake inputs first, then switch |

## Logic

- If $ARGUMENTS mentions "update": use `update`
- Otherwise: use `rebuild`

## Important notes

- `--impure` is required: `modules/hosts/shared.nix` and each host's `default.nix`
  do `import "/home/ebbe/erebus/secrets.nix"`, an absolute path outside the flake,
  which pure evaluation refuses. Everything else evaluates purely, so a failure
  mentioning `access to absolute path ... is forbidden` means `--impure` was dropped.
- In `nh os switch`, flags after `--` are passed through to `nixos-rebuild`; `--update`
  belongs before it, as above.
- There is no Home Manager switch. Home Manager is wired through the NixOS module
  (`home-manager.users.ebbe` in `modules/hosts/shared.nix`), and the flake exports no
  `homeConfigurations`, so home changes ship with a normal `rebuild`.
- **`git add` new files before rebuilding.** The flake source only contains git-*tracked*
  files. A dirty tree still contributes modified tracked files, so edits apply as expected,
  but a brand-new untracked file is silently dropped from the build — with no warning, and
  while a working-tree test of the very same code passes. This has already broken the
  desktop once: a new QML file was left untracked, so the built shell imported a module
  that wasn't there and the session came up with no bar. `git status --short` should show
  no `??` entries before a rebuild.
- If the build fails on a broken module, `nix flake check ~/erebus --impure` narrows it down.
- Quickshell's QML is read from the store at `assets/quickshell`, so shell changes also
  need a `rebuild` to take effect. To iterate without one, run the tree directly:
  `quickshell -p ~/erebus/assets/quickshell` (it hot-reloads on save, and runs alongside
  the live bar).

Run the command directly in the terminal after confirming with the user.
