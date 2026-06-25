{ self, inputs, ... }: {
  flake.nixosConfigurations.asusLaptop = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inherit inputs;
      secrets = import "/home/ebbe/erebus/secrets.nix";
    };
    modules = [
      self.nixosModules.asusLaptopConfiguration
      self.nixosModules.desktop-host
      {home-manager.sharedModules = [self.homeModules.asusLaptopHome];}
    ];
  };
}
