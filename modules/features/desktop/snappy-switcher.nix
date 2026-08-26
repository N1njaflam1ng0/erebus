{ inputs, ... }: {
  flake.homeModules.snappy-switcher = { pkgs, lib, config, options, ... }: 
  let
    snappy = inputs.snappy-switcher.packages.${pkgs.stdenv.hostPlatform.system}.default;
    hypr = config.wayland.windowManager.hyprland;
  in {
    home.packages = [snappy];

    xdg.configFile."snappy-switcher/config.ini".text = ''
      [general]
      mode = context
      show_workspace_badge = true
      follow_monitor = true

      [theme]
      name = erebus.ini

      [icons]
      theme = erebus-icons
      fallback = hicolor
      show_letter_fallback = true
    '';

    # Static palette, matching assets/quickshell/config/Colors.qml. Noctalia used
    # to render this from a template on every palette change; matugen takes that
    # job over in the theming phase.
    xdg.configFile."snappy-switcher/themes/erebus.ini".text = ''
      [colors]
      background = #121110ee
      card_bg = #1C1B19ff
      card_selected = #312F2Cff
      text_color = #FCE8C3ff
      subtext_color = #C5B088ff
      border_color = #E02C6Dff
      bundle_bg = #1C1B19cc
      badge_bg = #262522ff
      badge_text_color = #C5B088ff
      badge_bg_selected = #E02C6Dff
      badge_text_color_selected = #121110ff
    '';

    wayland.windowManager.hyprland.extraConfig = lib.mkIf hypr.enable (lib.mkAfter (
      if (hypr.configType or "conf") == "lua"
      then ''
        hl.bind("ALT + Tab",           hl.dsp.exec_cmd("snappy-switcher next --mod alt"))
        hl.bind("ALT + SHIFT + Tab",   hl.dsp.exec_cmd("snappy-switcher prev --mod alt"))
      ''
      else ''
        bind = ALT, Tab, exec, snappy-switcher next --mod alt
        bind = ALT SHIFT, Tab, exec, snappy-switcher prev --mod alt
      ''
    ));

    systemd.user.services.snappy-switcher = {
      Unit = {
        Description = "Snappy Switcher window switcher daemon";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${snappy}/bin/snappy-switcher --daemon";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    home.activation.snappySwitcherThemeDir = lib.hm.dag.entryBefore ["writeBoundary"] ''
      mkdir -p "$HOME/.config/snappy-switcher/themes"
    '';
  };
}