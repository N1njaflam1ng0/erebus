{ self, ... }: {
  # Offline Wikipedia/ZIM reader (kiwix-desktop)
  flake.nixosModules.kiwix = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.kiwix ];
  };
}
