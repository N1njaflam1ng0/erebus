{...}: {
  flake.nixosModules.core-packages = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      # --- System Utilities ---
      fastfetch
      tmux
      wget
      zip
      unzip
      dbus
      jq
      bc
      vlc

      # --- Screen Capture & OCR ---
      slurp
      grim
      satty
      imagemagick # (Provides magick)
      wl-clipboard # (Provides wl-copy)
      tesseract
      xdg-utils # (Provides xdg-open for Google Lens)
      wf-recorder # (For Screen Recording)

      gdu # Disk usage analyzer
      fd # Faster 'find'
      ripgrep # Faster 'grep'
      tldr # Simpler 'man' pages

      # --- Connectivity ---
      # Kept for nm-connection-editor, which the shell's wifi panel
      # (assets/quickshell/modules/network/WifiPanel.qml) shells out to for the
      # things it deliberately doesn't cover -- 802.1X, VPNs, static addresses.
      # The nm-applet tray icon itself is unused; Quickshell draws the bar.
      networkmanagerapplet
      bluez
      bluez-tools

      # --- Document Handling ---
      # No texlive here: development.nix pulls in texliveFull, which is a strict
      # superset (and texlive.combined.* is deprecated upstream anyway).
      pandoc
      poppler-utils
      libreoffice

      # --- Media / Visuals ---
      playerctl
      brightnessctl

      # --- Nix Tools ---
      nh
      nix-output-monitor
      nix-tree

      # --- Monitoring ---
      btop

      # --- Sound ---
      crosspipe

      # --- Extras ---
      spotify
    ];
  };
}
