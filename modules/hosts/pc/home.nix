{...}: {
  flake.homeModules.pcHome = {...}: {
    home.stateVersion = "26.05";

    # Monitor roles for the Quickshell bar. Names from `hyprctl -j monitors`.
    erebus.shell = {
      primary = "DP-1";
      left = "DP-3";
      right = "HDMI-A-1";
      outputs = [ "DP-1" "DP-3" "HDMI-A-1" ];
    };

    xdg.configFile."gtk-3.0/bookmarks" = {
      force = true;
      text = ''
        file:///home/ebbe/Pictures Pictures
        file:///home/ebbe/Downloads Downloads
        file:///mnt/storage Storage4TB
      '';
    };
  };
}
