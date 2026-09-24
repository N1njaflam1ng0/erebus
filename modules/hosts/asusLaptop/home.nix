{...}: {
  flake.homeModules.asusLaptopHome = {...}: {
    home.stateVersion = "26.05";

    # Single internal panel; no left/right roles on the laptop.
    erebus.shell = {
      primary = "eDP-1";
      outputs = [ "eDP-1" ];
    };
  };
}
