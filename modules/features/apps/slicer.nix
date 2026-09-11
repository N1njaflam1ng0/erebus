{ self, ... }: {
  flake.nixosModules.slicer = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      orca-slicer # Slicer; has built-in Ender-3 V3 KE profiles
      f3d # Quick STL/3MF preview
      meshlab # Mesh repair
    ];
  };
}
