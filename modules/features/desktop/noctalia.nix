{ self, inputs, ... }: {
  flake.nixosModules.noctalia = {...}: {
    imports = [inputs.noctalia.nixosModules.default];
    nix.settings.extra-substituters = ["https://noctalia.cachix.org"];
    nix.settings.extra-trusted-public-keys = ["noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="];
    programs.noctalia = {
      enable = true;
      package = null;
      recommendedServices.enable = true;
    };
  };

  flake.homeModules.noctalia = { pkgs, lib, ... }: 
  let
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
  in {
    imports = [inputs.noctalia.homeModules.default];
    programs.noctalia = {
      enable = true;
      settings =
        builtins.replaceStrings ["@FLAKE@"] ["${self}"]
        (builtins.readFile "${self}/assets/noctalia-config.toml");
    };

    home.packages = with pkgs; [
      noctaliaHyprExtra
      ffmpeg
      mpvpaper  
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
  };
}
