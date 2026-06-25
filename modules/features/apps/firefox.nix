{ self, inputs, ... }: {
  flake.nixosModules.firefox-devedition = { pkgs, ... }:  {
    environment.systemPackages = [ pkgs.firefox-devedition ];
  };
}