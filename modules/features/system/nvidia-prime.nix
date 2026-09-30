{...}: {
  # Hybrid AMD + NVIDIA: AMD drives the display, NVIDIA is kept for offload.
  # Shared verbatim by both hosts; override per host if one of them differs.
  flake.nixosModules.nvidia-prime = {
    config,
    pkgs,
    lib,
    ...
  }: {
    services.xserver.videoDrivers = ["amdgpu" "nvidia"];
    hardware.nvidia = {
      modesetting.enable = true;
      open = true;
      nvidiaSettings = true;
      # Read off boot.kernelPackages, so it follows asusLaptop's kernel pin.
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      powerManagement.enable = false;
      prime = {
        amdgpuBusId = "PCI:5:0:0";
        nvidiaBusId = "PCI:1:0:0";
        offload.enable = true;
        offload.enableOffloadCmd = true;
      };
    };

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

    # GPU monitoring in btop needs the CUDA build
    environment.systemPackages = [
      (lib.hiPrio (pkgs.btop.override {cudaSupport = true;}))
    ];

    boot.kernelParams = [
      "usbcore.autosuspend=-1"
    ];
  };
}
