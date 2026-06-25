{ self, ... }: {
  flake.nixosModules.discord = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.discord ];
  };
}
