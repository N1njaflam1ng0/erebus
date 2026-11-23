{ self, inputs, ... }: {
  flake.nixosModules.firefox-devedition = { pkgs, ... }:  {
    environment.systemPackages = [ pkgs.firefox-devedition ];
  };

  # Per-user, not xdg.mime: FHS-sandboxed apps (Discord) have their own /etc/xdg
  # and only see the default browser through ~/.config/mimeapps.list.
  flake.homeModules.firefox-devedition = { ... }: {
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = [ "firefox-devedition.desktop" ];
        "application/xhtml+xml" = [ "firefox-devedition.desktop" ];
        "x-scheme-handler/http" = [ "firefox-devedition.desktop" ];
        "x-scheme-handler/https" = [ "firefox-devedition.desktop" ];
      };
    };
  };
}
