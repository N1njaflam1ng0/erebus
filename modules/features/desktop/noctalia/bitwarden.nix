{ ... }: {
  flake.homeModules.bitwarden = { pkgs, lib, config, options, ... }: {
    home.packages = [ pkgs.bitwarden-cli ];

    programs = lib.optionalAttrs (options.programs ? noctalia) {
      noctalia.settings.plugins.enabled = [ "noctalia/bitwarden" ];
    };

    wayland.windowManager.hyprland.extraConfig = lib.mkIf config.wayland.windowManager.hyprland.enable (lib.mkAfter ''
      hl.bind(mod .. " + B", hl.dsp.exec_cmd("noctalia msg panel-toggle noctalia/bitwarden:unlock"))
    '');
  };
}
