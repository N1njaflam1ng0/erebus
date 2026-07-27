{ ... }: {
  flake.homeModules.nix-monitor = { lib, config, options, ... }: {
    programs = lib.optionalAttrs (options.programs ? noctalia) {
      noctalia.settings.plugins.enabled = [ "avivbintangaringga/nix-monitor" ];
    };

    wayland.windowManager.hyprland.extraConfig = lib.mkIf config.wayland.windowManager.hyprland.enable (lib.mkAfter ''
      hl.bind(mod .. " + N", hl.dsp.exec_cmd("noctalia msg panel-toggle avivbintangaringga/nix-monitor:panel"))
    '');
  };
}
