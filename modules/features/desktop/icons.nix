{ self, ... }: {
  # Icon theme modelled on roosta's ritual-icons: a thin theme that owns no icons
  # of its own and exists purely for the Inherits chain, so gaps in candy-icons
  # fall through to Papirus instead of rendering blank.
  flake.homeModules.icons = { pkgs, lib, ... }:
  let
    indexTheme = pkgs.writeText "erebus-icons-index.theme" ''
      [Icon Theme]
      Name=erebus-icons
      Comment=Erebus desktop icons
      Inherits=candy-icons,Papirus-Dark,breeze-dark,Adwaita,hicolor
      FollowsColorScheme=true

      Directories=apps/scalable

      [apps/scalable]
      Size=96
      Context=Applications
      MinSize=8
      MaxSize=512
      Type=Scalable
    '';

    erebus-icons = pkgs.runCommand "erebus-icons" { } ''
      dir="$out/share/icons/erebus-icons"
      mkdir -p "$dir/apps/scalable"
      cp ${indexTheme} "$dir/index.theme"
    '';
  in {
    home.packages = with pkgs; [
      candy-icons
      papirus-icon-theme
      erebus-icons
    ];

    gtk.iconTheme = {
      name = "erebus-icons";
      package = erebus-icons;
    };

    # GTK reads the theme from settings.ini, but Qt6 reads it from qt6ct — and
    # qt6ct.conf does not exist until the GUI is opened once, so Qt apps (the
    # Quickshell bar included) fall back to hicolor and render blank tiles.
    # Seed only the icon theme, and leave the file writable so qt6ct can still
    # manage the rest of its own settings.
    home.activation.qt6ctIconTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      conf="$HOME/.config/qt6ct/qt6ct.conf"
      if [ ! -f "$conf" ]; then
        mkdir -p "$(dirname "$conf")"
        printf '[Appearance]\nicon_theme=erebus-icons\n' > "$conf"
      elif ! ${pkgs.gnugrep}/bin/grep -q '^icon_theme=' "$conf"; then
        ${pkgs.gnused}/bin/sed -i '/^\[Appearance\]/a icon_theme=erebus-icons' "$conf"
      fi
    '';
  };
}
