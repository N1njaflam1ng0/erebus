{ self, ... }: {
  flake.nixosModules.asusLaptopConfiguration = { config, pkgs, lib, inputs, ... }: {
    imports = [
      self.nixosModules.asusLaptopHardware
    ];

    networking.hostName = "asusLaptop";
    system.stateVersion = "26.05";

    # This machine's keyboard is dead on 6.18.49 — see the nixpkgs-kernel input
    # in flake.nix. nvidiaPackages below is read off boot.kernelPackages, so the
    # NVIDIA module follows this pin automatically and stays in step.
    # Only the kernel itself is pinned; everything built against it (the NVIDIA
    # module below included) still comes from the main nixpkgs via
    # linuxPackagesFor, so this does not drag the graphics driver backwards too.
    boot.kernelPackages = pkgs.linuxPackagesFor
      (import inputs.nixpkgs-kernel {
        system = pkgs.stdenv.hostPlatform.system;
        config = config.nixpkgs.config;
      }).linuxPackages.kernel;

    # Hybrid AMD + NVIDIA laptop: let AMD drive the display and keep NVIDIA for offload.
    services.xserver.videoDrivers = ["amdgpu" "nvidia"];
    hardware.nvidia = {
      modesetting.enable = true;
      open = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      powerManagement.enable = false;
      prime = {
        amdgpuBusId = "PCI:5:0:0";
        nvidiaBusId = "PCI:1:0:0";
        offload.enable = true;
        offload.enableOffloadCmd = true;
      };
    };

    # Graphics stack
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = [pkgs.nvidia-vaapi-driver];
    };

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "nvidia";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      NVD_BACKEND = "direct";
      # nvidia-vaapi-driver runs in Firefox's RDD process; the decoder
      # can't reach the GPU with the sandbox on
      MOZ_DISABLE_RDD_SANDBOX = "1";
    };

    # GPU monitoring in btop needs the CUDA build; hiPrio wins over the
    # plain btop from core-packages
    environment.systemPackages = [
      (lib.hiPrio (pkgs.btop.override {cudaSupport = true;}))
    ];

    boot.kernelParams = [
      "usbcore.autosuspend=-1"
    ];

    # Intel AX200: keep the firmware out of power-save entirely. power_scheme=1
    # is CAM (never sleep); the mvm scheme is what actually gates PS, so
    # power_save=0 alone is not enough. Pairs with
    # networking.networkmanager.wifi.powersave = false in base-system.
    boot.extraModprobeConfig = ''
      options iwlwifi power_save=0
      options iwlmvm power_scheme=1
    '';

    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.grub.enable = true;
    boot.loader.grub.devices = ["nodev"];
    boot.loader.grub.efiSupport = true;
    boot.loader.grub.useOSProber = true;
    boot.loader.grub.theme = "${self.inputs.grubermeister.packages.${pkgs.stdenv.hostPlatform.system}.default}";
    
    boot.loader.grub.entryOptions    = "--unrestricted --class nixos";
    boot.loader.grub.subEntryOptions = "--unrestricted --class nixos-generation";
  };
}