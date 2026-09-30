{self, ...}: {
  flake.nixosModules.pcConfiguration = {...}: {
    imports = [
      self.nixosModules.pcHardware
      self.nixosModules.nvidia-prime
      self.nixosModules.grub
    ];

    networking.hostName = "pc";
    system.stateVersion = "26.05";

    systemd.tmpfiles.rules = [
      "d /mnt/storage 0755 ebbe users - -"
    ];

    boot.loader.timeout = 10;
  };
}
