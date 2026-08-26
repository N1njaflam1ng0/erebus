{ self, ... }: {
  flake.homeModules.asusLaptopHome = { config, pkgs, inputs, ... }: {
    home.stateVersion = "26.05";

    # Single internal panel; no left/right roles on the laptop.
    erebus.shell = {
      primary = "eDP-1";
      outputs = [ "eDP-1" ];
    };

    # Hardware video decode (NVDEC) via nvidia-vaapi-driver.
    # Only works in Firefox — Chromium/Electron can't use this driver.
    # Needs MOZ_DISABLE_RDD_SANDBOX=1, set in asusLaptop-configuration.
    programs.firefox.profiles.chris.settings = {
      "media.hardware-video-decoding.force-enabled" = true; # Firefox 137+
      "media.ffmpeg.vaapi.enabled" = true; # pre-137 fallback, harmless now
      "media.rdd-ffmpeg.enabled" = true;
    };
  };
}
