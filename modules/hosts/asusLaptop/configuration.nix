{self, ...}: {
  flake.nixosModules.asusLaptopConfiguration = {
    config,
    pkgs,
    inputs,
    ...
  }: {
    imports = [
      self.nixosModules.asusLaptopHardware
      self.nixosModules.nvidia-prime
      self.nixosModules.grub
    ];

    networking.hostName = "asusLaptop";
    system.stateVersion = "26.05";

    # This machine's keyboard is dead on 6.18.49 — see the nixpkgs-kernel input
    # in flake.nix. nvidiaPackages (nvidia-prime.nix) is read off
    # boot.kernelPackages, so the NVIDIA module follows this pin automatically.
    # Only the kernel itself is pinned; everything built against it (the NVIDIA
    # module included) still comes from the main nixpkgs via linuxPackagesFor,
    # so this does not drag the graphics driver backwards too.
    boot.kernelPackages = pkgs.linuxPackagesFor
      (import inputs.nixpkgs-kernel {
        system = pkgs.stdenv.hostPlatform.system;
        config = config.nixpkgs.config;
      }).linuxPackages.kernel;

    # Intel AX200: keep the firmware out of power-save entirely. power_scheme=1
    # is CAM (never sleep); the mvm scheme is what actually gates PS, so
    # power_save=0 alone is not enough. Pairs with
    # networking.networkmanager.wifi.powersave = false in base-system.
    boot.extraModprobeConfig = ''
      options iwlwifi power_save=0
      options iwlmvm power_scheme=1
    '';
  };
}
