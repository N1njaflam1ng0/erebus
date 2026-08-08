{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.noctalia = {...}: {
    imports = [inputs.noctalia.nixosModules.default];
    disabledModules = ["programs/wayland/noctalia.nix"];
    nix.settings.extra-substituters = ["https://noctalia.cachix.org"];
    nix.settings.extra-trusted-public-keys = ["noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="];
    programs.noctalia = {
      enable = true;
      package = null;
      recommendedServices.enable = true;
    };
  };

  flake.homeModules.noctalia = {
    pkgs,
    lib,
    ...
  }: let
    hyprctl = "${inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland}/bin/hyprctl";
    noctaliaHyprExtra = pkgs.writeShellScriptBin "noctalia-hypr-extra" ''
      colors="$HOME/.config/noctalia/colors.json"
      out="$HOME/.config/hypr/noctalia-extra.lua"
      get() { awk -F'"' -v k="$1" '$2==k{gsub("#","",$(NF-1));print $(NF-1)}' "$colors" 2>/dev/null; }
      if [ -f "$colors" ]; then
        on_sec=$(get mOnSecondary)
        on_surf=$(get mOnSurface)
      fi
      on_sec=''${on_sec:-000000}
      on_surf=''${on_surf:-d1d1c7}

      # Persist for next hyprland startup
      printf 'hl.config({ group = { groupbar = { text_color = "rgb(%s)", text_color_inactive = "rgb(%s)" } } })\n' \
        "$on_sec" "$on_surf" > "$out"

      # Apply immediately at runtime, avoids race with noctalia.lua reload debounce
      hypr_sig=$(ls /run/user/$(id -u)/hypr/ 2>/dev/null | head -1)
      if [ -n "$hypr_sig" ]; then
        HYPRLAND_INSTANCE_SIGNATURE="$hypr_sig" ${hyprctl} keyword group:groupbar:text_color "rgb(''${on_sec})"
        HYPRLAND_INSTANCE_SIGNATURE="$hypr_sig" ${hyprctl} keyword group:groupbar:text_color_inactive "rgb(''${on_surf})"
      fi
    '';
    # Noctalia's GUI writes runtime overrides to ~/.local/state/noctalia/settings.toml,
    # which shadow the flake-managed config.toml. Recursively drop every key the repo
    # toml declares so the flake stays the source of truth across rebuilds; keys only
    # the GUI/runtime knows about (wallpaper favorites, etc.) are kept per-machine.
    noctaliaPruneOverrides =
      pkgs.writers.writePython3Bin "noctalia-prune-overrides" {
        libraries = [pkgs.python3Packages.tomli-w];
      } ''
        import os
        import sys
        import tomllib

        import tomli_w


        def prune(base, over):
            out = {}
            for key, value in over.items():
                if key not in base:
                    out[key] = value
                elif isinstance(value, dict) and isinstance(base[key], dict):
                    sub = prune(base[key], value)
                    if sub:
                        out[key] = sub
            return out


        base_path = os.path.expanduser("~/.config/noctalia/config.toml")
        overrides_path = os.path.expanduser(
            "~/.local/state/noctalia/settings.toml"
        )
        if not (os.path.exists(base_path) and os.path.exists(overrides_path)):
            sys.exit(0)
        with open(base_path, "rb") as f:
            base = tomllib.load(f)
        with open(overrides_path, "rb") as f:
            overrides = tomllib.load(f)
        pruned = prune(base, overrides)
        if pruned != overrides:
            with open(overrides_path, "wb") as f:
                tomli_w.dump(pruned, f)
      '';
    # The gSlapper plugin owns assignments.json at runtime, so nothing substitutes
    # @FLAKE@ into it and its saved paths pin the store hash of whatever flake source
    # was current when you picked the wallpaper. That keeps working until the old
    # generation is garbage collected, then the assignment resolves to nothing and the
    # output silently stays bare. Repoint it at activation so saved wallpapers track
    # the current source. Anchored on /assets/backgrounds/ so it can only ever rewrite
    # wallpaper paths, never some other store reference the plugin might hold.
    noctaliaRepointAssignments = pkgs.writeShellScriptBin "noctalia-repoint-assignments" ''
      f="$HOME/.local/state/noctalia/plugins/data/nomadcxx/gslapper/assignments.json"
      [ -f "$f" ] || exit 0
      ${pkgs.gnused}/bin/sed -i -E \
        's|/nix/store/[a-z0-9]+-source/assets/backgrounds/|${self}/assets/backgrounds/|g' "$f"
    '';
    # Upstream wraps the gslapper binary with GST_PLUGIN_SYSTEM_PATH_1_0, but the
    # noctalia plugin also shells out to a bare gst-launch-1.0 to render preview
    # thumbnails. Unwrapped it resolves no elements at all ("no element filesrc")
    # and every thumbnail comes out blank, so wrap it with the same plugin set
    # gslapper itself gets — base/good/bad covers H.264 via openh264dec, which is
    # what gslapper can play anyway, so gst-libav would only widen the closure.
    gstLaunch = pkgs.symlinkJoin {
      name = "gst-launch-wrapped";
      paths = [pkgs.gst_all_1.gstreamer.bin];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/gst-launch-1.0 \
          --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${lib.makeSearchPath "lib/gstreamer-1.0" (with pkgs.gst_all_1; [
          gstreamer.out
          gst-plugins-base
          gst-plugins-good
          gst-plugins-bad
        ])}"
      '';
    };
  in {
    imports = [inputs.noctalia.homeModules.default];
    programs.noctalia = {
      enable = true;
      # Attrset (not raw TOML string) so other modules
      # can merge into settings. @FLAKE@ is substituted after parsing because
      # fromTOML rejects strings with store-path context.
      settings = let
        subst = v:
          if builtins.isString v
          then builtins.replaceStrings ["@FLAKE@"] ["${self}"] v
          else if builtins.isAttrs v
          then builtins.mapAttrs (_: subst) v
          else if builtins.isList v
          then map subst v
          else v;
      in
        subst (builtins.fromTOML (builtins.readFile (self + "/assets/noctalia-config.toml")));
    };

    home.packages = with pkgs; [
      noctaliaHyprExtra
      ffmpeg
      # gSlapper plugin runtime deps: gslapper, gst-launch-1.0, socat, pkill.
      inputs.gslapper.packages.${pkgs.stdenv.hostPlatform.system}.gslapper
      gstLaunch
      socat
      procps
    ];

    systemd.user.services.noctalia-hypr-extra = {
      Unit.Description = "Update Hyprland extra colors from Noctalia palette";
      Service = {
        Type = "oneshot";
        ExecStart = "${noctaliaHyprExtra}/bin/noctalia-hypr-extra";
      };
    };

    systemd.user.paths.noctalia-hypr-extra = {
      Unit.Description = "Watch Noctalia Hyprland config for palette changes";
      Path.PathModified = "%h/.config/hypr/noctalia.lua";
      Install.WantedBy = ["default.target"];
    };

    home.activation.noctaliaHyprConf = lib.hm.dag.entryBefore ["writeBoundary"] ''
      if [ ! -f "$HOME/.config/hypr/noctalia.lua" ]; then
        mkdir -p "$HOME/.config/hypr"
        touch "$HOME/.config/hypr/noctalia.lua"
      fi
      if [ ! -f "$HOME/.config/hypr/noctalia-extra.lua" ]; then
        mkdir -p "$HOME/.config/hypr"
        touch "$HOME/.config/hypr/noctalia-extra.lua"
      fi
      ${noctaliaHyprExtra}/bin/noctalia-hypr-extra || true
    '';

    # Runs after config.toml is in place; noctalia watches settings.toml and reloads live.
    home.activation.noctaliaPruneOverrides = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${noctaliaPruneOverrides}/bin/noctalia-prune-overrides || true
    '';

    # Takes effect when the gSlapper plugin next loads assignments.json; a running
    # noctalia still holds the old paths in memory until it restarts.
    home.activation.noctaliaRepointAssignments = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${noctaliaRepointAssignments}/bin/noctalia-repoint-assignments || true
    '';
  };
}
