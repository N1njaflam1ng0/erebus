{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.hyprland = {
    pkgs,
    lib,
    ...
  }: {
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      xwayland.enable = true;
    };

    xdg.portal = {
      enable = true;
      config = {
        hyprland = {
          default = ["hyprland" "gtk"];
          "org.freedesktop.impl.portal.ScreenCast" = "hyprland";
        };
      };

      extraPortals = lib.mkForce [
        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
      ];
    };
  };

  flake.homeModules.hyprland = {
    pkgs,
    config,
    lib,
    ...
  }: let
    terminal = "${pkgs.kitty}/bin/kitty";
    fm = "${pkgs.nautilus}/bin/nautilus";
  in {
    home.packages = with pkgs; [hyprpicker satty];

    home.activation.hyprlandLuaCleanup = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
      if [ -f "$HOME/.config/hypr/hyprland.lua" ] && [ ! -L "$HOME/.config/hypr/hyprland.lua" ]; then
        rm -f "$HOME/.config/hypr/hyprland.lua"
      fi
    '';

    home.file.".config/hypr/plugins/split-monitor-workspaces" = {
      source = inputs.split-monitor-workspaces;
    };

    home.activation.hyprMonitorsConf = lib.hm.dag.entryBefore ["writeBoundary"] ''
      if [ -L "$HOME/.config/hypr/monitors.lua" ]; then
        rm "$HOME/.config/hypr/monitors.lua"
      fi
      if [ ! -f "$HOME/.config/hypr/monitors.lua" ]; then
        mkdir -p "$HOME/.config/hypr"
        touch "$HOME/.config/hypr/monitors.lua"
      fi
    '';

    home.pointerCursor = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };

    wayland.windowManager.hyprland = {
      enable = true;
      configType = "lua";
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;

      extraConfig = ''
        local mod = "SUPER"
        local terminal = "${terminal}"
        local fm = "${fm}"

        hl.config({
          general = {
            gaps_in = 1,
            gaps_out = 1,
            border_size = 2,
            resize_on_border = true,
            allow_tearing    = false,
            layout           = "dwindle",
          },
          group = {
            insert_after_current = true,
            focus_removed_window = true,
            groupbar = {
              enabled           = true,
              render_titles     = true,
              gradients         = true,
              font_size         = 16,
              font_weight_active = "ultraheavy",
              height            = 24,
            },
          },
          decoration = {
            rounding         = 0,
            rounding_power   = 2,
            active_opacity   = 1.0,
            inactive_opacity = 1.0,
            shadow = {
              enabled      = true,
              range        = 4,
              render_power = 3,
            },
            blur = {
              enabled  = true,
              size     = 3,
              passes   = 1,
              vibrancy = 0.1696,
            },
          },
          animations = { enabled = true },
          input = {
            kb_layout    = "dk",
            follow_mouse = 1,
            force_no_accel = 1,
            sensitivity  = 1,
            touchpad = {
              disable_while_typing = true,
              natural_scroll       = true,
            },
          },
          misc = {
            disable_hyprland_logo        = true,
            force_default_wallpaper      = 0,
            animate_manual_resizes       = false,
            animate_mouse_windowdragging = false,
          },
        })

        hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
        hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
        hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
        hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
        hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

        hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
        hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
        hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
        hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
        hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
        hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
        hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
        hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
        hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
        hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
        hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
        hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
        hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
        hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
        hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
        hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

        hl.on("hyprland.start", function()
          hl.exec_cmd("noctalia --daemon")
        end)

        local _hypr_dir = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr"
        package.path = _hypr_dir .. "/?.lua;" .. package.path
        require("noctalia").apply_theme()
        local smw = require("plugins.split-monitor-workspaces")
        smw.setup({ workspace_count = 9 })
        dofile(_hypr_dir .. "/monitors.lua")
        dofile(_hypr_dir .. "/noctalia-extra.lua")

        hl.bind(mod .. " + S",         hl.dsp.exec_cmd("firefox-devedition"))
        hl.bind(mod .. " + Q",   hl.dsp.window.close())
        hl.bind(mod .. " + C",         hl.dsp.exec_cmd(terminal))
        hl.bind(mod .. " + Space",     hl.dsp.window.float({ action = "toggle" }))
        hl.bind(mod .. " + E",         hl.dsp.exec_cmd(fm))

        hl.bind(mod .. " + SHIFT + S",   hl.dsp.exec_cmd("noctalia msg screenshot-region"))
        hl.bind(mod .. " + U",         hl.dsp.exec_cmd("noctalia msg panel-toggle session"))
        hl.bind(mod .. " + V",         hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"))
        hl.bind(mod .. " + T",         hl.dsp.exec_cmd("noctalia msg settings-toggle"))
        hl.bind(mod .. " + R",         hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))
        hl.bind("ALT + Space",         hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))
        hl.bind(mod .. " + M",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))

        hl.bind(mod .. " + L",         hl.dsp.exec_cmd("noctalia msg session lock"))

        hl.bind(mod .. " + P",         hl.dsp.exec_cmd("hyprpicker -a"))
        hl.bind(mod .. " + SHIFT + M",   hl.dsp.exec_cmd("hypr-mirror-toggle"))

        hl.bind(mod .. " + G",           hl.dsp.group.toggle())
        hl.bind(mod .. " + Tab",         hl.dsp.group.next())
        hl.bind(mod .. " + SHIFT + Tab", hl.dsp.group.prev())
        hl.bind(mod .. " + F",           hl.dsp.window.move({ out_of_group = true }))

        hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
        hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
        hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }))
        hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }))

        hl.bind(mod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
        hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
        hl.bind(mod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
        hl.bind(mod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

        hl.bind(mod .. " + CTRL + right", hl.dsp.window.resize({ x = 30,  y = 0,   relative = true }), { repeating = true })
        hl.bind(mod .. " + CTRL + left",  hl.dsp.window.resize({ x = -30, y = 0,   relative = true }), { repeating = true })
        hl.bind(mod .. " + CTRL + up",    hl.dsp.window.resize({ x = 0,   y = -30, relative = true }), { repeating = true })
        hl.bind(mod .. " + CTRL + down",  hl.dsp.window.resize({ x = 0,   y = 30,  relative = true }), { repeating = true })

        hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
        hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

        hl.bind("XF86AudioPlay",        hl.dsp.exec_cmd("playerctl play-pause"))
        hl.bind("XF86AudioNext",        hl.dsp.exec_cmd("playerctl next"))
        hl.bind("XF86AudioPrev",        hl.dsp.exec_cmd("playerctl previous"))
        hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
        hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true })
        hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))

        for i = 1, 9 do
          hl.bind(mod .. " + " .. i,         smw.workspace(tostring(i)))
          hl.bind(mod .. " + SHIFT + " .. i, smw.move_to_workspace(tostring(i)))
        end
      '';
    };
  };
}
