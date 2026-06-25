{ self, ... }: {
  flake.homeModules.pcHome = { config, pkgs, inputs, ... }: {
    home.stateVersion = "26.05";

    # Hardware video decode (NVDEC) via nvidia-vaapi-driver.
    # Only works in Firefox — Chromium/Electron can't use this driver.
    # Needs MOZ_DISABLE_RDD_SANDBOX=1, set in pc-configuration.
    programs.firefox.profiles.chris.settings = {
      "media.hardware-video-decoding.force-enabled" = true; # Firefox 137+
      "media.ffmpeg.vaapi.enabled" = true; # pre-137 fallback, harmless now
      "media.rdd-ffmpeg.enabled" = true;
    };
  };
}
