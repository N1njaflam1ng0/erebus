{ self, ... }: {
  flake.nixosModules.stoat = { pkgs, ... }: {
    environment.systemPackages = [
      # Wrapped so every launch (incl. the .desktop entry) targets the self-hosted instance
      (pkgs.symlinkJoin {
        name = "stoat-desktop";
        paths = [ pkgs.stoat-desktop ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/stoat-desktop \
            --add-flags "--force-server=https://stoat.hivemindcloud.dk"
        '';
      })
    ];
  };
}
