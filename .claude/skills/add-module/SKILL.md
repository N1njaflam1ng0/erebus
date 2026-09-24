---
name: add-module
description: Scaffold a new feature module in this NixOS config following the flake-parts + import-tree pattern
---

Help the user add a new feature module under `modules/features/`. `import-tree` picks the
file up automatically, but that only *declares* the module — it still has to be listed in
`profiles.nix` or `shared.nix` to take effect. See Step 4.

## Step 1: Clarify scope

Ask (or infer from $ARGUMENTS):
1. **Module name** — what to call it (e.g., `neovim`, `docker`, `vpn`)
2. **Scope** — NixOS system module, Home Manager module, or both?
3. **Purpose** — brief description of what it configures

## Step 2: Propose the file path and structure

Features are grouped by category, so the target is `modules/features/<category>/<name>.nix`.
Existing categories: `apps/`, `desktop/`, `development/`, `gaming/`, `system/`, `terminal/`,
`custom-commands/`. Add a new category directory only if none fits.

If it needs several related files, use a subdirectory — `modules/features/desktop/quickshell/`
is the worked example.

Show the user the skeleton before writing it.

## Step 3: Write the module

**Home Manager module only:**
```nix
{ self, inputs, ... }: {
  flake.homeModules.<name> = { pkgs, lib, config, ... }: {
    # home-manager options here
  };
}
```

**NixOS system module only:**
```nix
{ self, inputs, ... }: {
  flake.nixosModules.<name> = { pkgs, lib, config, ... }: {
    # nixos options here
  };
}
```

**Both (system + home):**
```nix
{ self, inputs, ... }: {
  flake.nixosModules.<name> = { pkgs, lib, config, ... }: {
    # system-level config (services, security, networking, etc.)
  };

  flake.homeModules.<name> = { pkgs, lib, config, ... }: {
    # per-user config (dotfiles, programs, env vars, etc.)
  };
}
```

`flake.homeModules` is not a flake-parts built-in — it is declared as an option in
`modules/transposition.nix`.

## Step 4: Wire it in

Modules are **not** enabled per host. Add the new one to the aggregate that matches its scope:

- Home Manager → the `imports` list in `modules/features/profiles.nix`
  (`flake.homeModules.profile-ebbe`), as `self.homeModules.<name>`
- NixOS → the `imports` list in `modules/hosts/shared.nix`
  (`flake.nixosModules.desktop-host`), as `self.nixosModules.<name>`

Both aggregates apply to every host. `modules/hosts/<host>/default.nix` is only for
genuinely host-specific modules.

If the module should be opt-in per host, give it an option under `erebus.*` and set that
in `modules/hosts/<host>/home.nix` or `configuration.nix` —
`modules/features/desktop/quickshell/quickshell.nix` (`options.erebus.shell`) is the pattern.

## Step 5: Verify

`nix flake check ~/erebus --impure` catches eval errors; `rebuild` applies it.

## Notes

- `import-tree` picks up any `.nix` file under `modules/` automatically — no manual imports.
  It **skips** files whose basename starts with `_`, which is how `_lock.nix` and
  `_greeter-theme.nix` stay plain functions that other modules `import` by hand.
- Use `inputs.<flake-name>.packages.${pkgs.system}.<pkg>` to reference packages from flake
  inputs (e.g., Hyprland).
- Secrets arrive as a **module argument**, not an import: take `secrets` in the module's
  arg set (`{ pkgs, secrets, ... }:`) and use `secrets.<key>`. It is supplied by
  `extraSpecialArgs`/`specialArgs` in `modules/hosts/shared.nix` and each host's
  `default.nix`. This is also why every rebuild needs `--impure`.
- The `{ self, inputs, ... }:` top-level args are flake-parts module args, not NixOS module args.
- A PostToolUse hook runs `alejandra` on every `.nix` file written, so don't hand-format.
