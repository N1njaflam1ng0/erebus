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
      name = noctalia.ini

      [icons]
      theme = Adwaita
      fallback = hicolor
      show_letter_fallback = true
    '';

    # Rendered by Noctalia into ~/.config/snappy-switcher/themes/noctalia.ini
    xdg.configFile."noctalia/templates/snappy-switcher.ini".text = ''
      [colors]
      background = {{colors.surface.default.hex}}ee
      card_bg = {{colors.surface_container.default.hex}}ff
      card_selected = {{colors.surface_container_high.default.hex}}ff
      text_color = {{colors.on_surface.default.hex}}ff
      subtext_color = {{colors.on_surface_variant.default.hex}}ff
      border_color = {{colors.primary.default.hex}}ff
      bundle_bg = {{colors.surface_container.default.hex}}cc
      badge_bg = {{colors.secondary_container.default.hex}}ff
      badge_text_color = {{colors.on_secondary_container.default.hex}}ff
      badge_bg_selected = {{colors.primary.default.hex}}ff
      badge_text_color_selected = {{colors.on_primary.default.hex}}ff
    '';

    # The daemon reads config + theme once at startup with no reload IPC,
    # so the post_hook restarts it whenever the palette changes. Only
    # registered when the noctalia home module is imported by the consumer.
    programs = lib.optionalAttrs (options.programs ? noctalia) {
      noctalia.settings.theme.templates.user.snappy-switcher = {
        enabled = true;
        input_path = "~/.config/noctalia/templates/snappy-switcher.ini";
        output_path = "~/.config/snappy-switcher/themes/noctalia.ini";
        post_hook = "systemctl --user restart snappy-switcher.service";
      };
    };

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