{ self, ... }: {
  flake.nixosModules.asusLaptopConfiguration = { config, pkgs, lib, ... }: {
    imports = [
      self.nixosModules.asusLaptopHardware
    ];

    networking.hostName = "asusLaptop";
    system.stateVersion = "26.05";

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

    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.grub.enable = true;
    boot.loader.grub.devices = ["nodev"];
    boot.loader.grub.efiSupport = true;
    boot.loader.grub.useOSProber = true;
  };
}
