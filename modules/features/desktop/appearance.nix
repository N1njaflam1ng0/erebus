{ self, ... }: {
  flake.homeModules.appearance = {pkgs, ...}: {
    gtk = {
      enable = true;
      gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
      gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
    };

    # Qt theming via qt6ct/qt5ct. icons.nix seeds qt6ct.conf with the icon theme;
    # colour schemes land here once matugen templating is in place.
    qt = {
      enable = true;
      platformTheme.name = "qtct";
    };

    home.packages = with pkgs; [
      adw-gtk3
      kdePackages.qt6ct
      libsForQt5.qt5ct
    ];
  };
}
