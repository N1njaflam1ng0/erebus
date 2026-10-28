{self, ...}: {
  flake.nixosModules.asusLaptopConfiguration = {...}: {
    imports = [
      self.nixosModules.asusLaptopHardware
      self.nixosModules.nvidia-prime
      self.nixosModules.grub
    ];

    networking.hostName = "asusLaptop";
    system.stateVersion = "26.05";

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
