{ ... }: {
  flake.homeModules.hypr-screen-mirror = { pkgs, lib, config, options, ... }: {
    home.packages = [ pkgs.socat ];

    programs = lib.optionalAttrs (options.programs ? noctalia) {
      noctalia.settings.plugins.enabled = [ "profidev/hypr-screen-mirror" ];
    };

    wayland.windowManager.hyprland.extraConfig = lib.mkIf config.wayland.windowManager.hyprland.enable (lib.mkAfter ''
      hl.bind(mod .. " + M", hl.dsp.exec_cmd("noctalia msg panel-toggle profidev/hypr-screen-mirror:panel"))
    '');
  };
}
