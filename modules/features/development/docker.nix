{ self, ... }: {
  flake.nixosModules.docker = { pkgs, ... }: {
    virtualisation.docker.rootless = {
      enable = true;
      setSocketVariable = true;
    };
    users.extraGroups.docker.members = [ "ebbe" ];
  };
}