{ self, ... }: {
  flake.homeModules.gui-terminal = {pkgs, ...}: {
    programs.ghostty = {
      enable = true;
      settings = {
        "font-family" = "CaskaydiaCove Nerd Font";
        "font-size" = 12;
        "window-padding-x" = 4;
        "window-padding-y" = 4;
        "window-decoration" = "none";
        "shell-integration" = "none";
        "bell-features" = "no-audio";
        theme = "Ayu";
      };
    };
  };
}
