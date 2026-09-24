{...}: {
  # wl-clipboard comes from environment.systemPackages (core-packages.nix); the
  # helpers that need it already call it by store path.
  flake.homeModules.clipboard = { ... }: {
    services.cliphist = {
      enable = true;
      allowImages = true;
      extraOptions = [ "-max-items" "500" ];
    };
  };
}
