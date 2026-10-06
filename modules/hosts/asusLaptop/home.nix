{...}: {
  flake.homeModules.asusLaptopHome = {...}: {
    home.stateVersion = "26.05";

    # Single internal panel; no left/right roles on the laptop.
    programs.erebus-shell.outputs.primary = "eDP-1";
  };
}
