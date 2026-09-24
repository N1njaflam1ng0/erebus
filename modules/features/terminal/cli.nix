{...}: {
  # Fish is enabled system-wide in modules/features/system/users.nix, which is
  # also where the login shell is set -- there is no nixosModules.cli any more.
  flake.homeModules.cli = { pkgs, lib, ... }: {
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        set -gx MAMBA_EXE "${pkgs.micromamba}/bin/micromamba"
        set -gx MAMBA_ROOT_PREFIX "$HOME/micromamba"
        eval "$($MAMBA_EXE shell hook --shell fish --root-prefix $MAMBA_ROOT_PREFIX)"
      '';
    };

    programs.eza = { enable = true; enableFishIntegration = true; extraOptions = [ "--icons" "--group-directories-first" ]; };
    programs.zoxide = { enable = true; enableFishIntegration = true; };
    programs.bat = { enable = true; config.theme = "Dracula"; };
    programs.direnv = { enable = true; nix-direnv.enable = true; };
  };
}