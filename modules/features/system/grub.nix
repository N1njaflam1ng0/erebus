{inputs, ...}: {
  flake.nixosModules.grub = {pkgs, ...}: {
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.grub = {
      enable = true;
      devices = ["nodev"];
      efiSupport = true;
      useOSProber = true;
      theme = "${inputs.grubermeister.packages.${pkgs.stdenv.hostPlatform.system}.default}";
      entryOptions = "--unrestricted --class nixos";
      subEntryOptions = "--unrestricted --class nixos-generation";
    };
  };
}
