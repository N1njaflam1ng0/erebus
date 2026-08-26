{inputs, ...}: {
  # hypr-mirror-toggle used to live here. It was built on `hyprctl keyword`,
  # which answers "unknown request" under this Hyprland's Lua config, so it had
  # been a no-op regardless; it also depended on the noctalia-generated
  # ~/.config/rofi/noctalia.rasi. Mirroring is now erebus-monitors (SUPER+P).
  flake.homeModules.wdisplays = { pkgs, ... }: let
    hyprlandPkg = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    realHyprctl = "${hyprlandPkg}/bin/hyprctl";
    
    saveMonitors = pkgs.writeShellScriptBin "hypr-save-monitors" ''
      ${realHyprctl} -j monitors | ${pkgs.python3}/bin/python3 -c "
      import json, sys
      out = []
      for m in json.load(sys.stdin):
          n = m['name']
          if m.get('disabled'):
              out.append(f'hl.monitor({{ output = \"{n}\", disabled = true }})')
              continue
          w, h = m['width'], m['height']
          r = m['refreshRate']
          x, y = m['x'], m['y']
          s = m['scale']
          mirror = m.get('mirrorOf', 'none')
          lines = [
              'hl.monitor({',
              f'  output   = \"{n}\",',
              f'  mode     = \"{w}x{h}@{r}\",',
              f'  position = \"{x}x{y}\",',
              f'  scale    = {s},',
          ]
          if mirror != 'none':
              lines.append(f'  mirror   = \"{mirror}\",')
          lines.append('})')
          out.append('\n'.join(lines))
      print('\n\n'.join(out))
      " > ~/.config/hypr/monitors.lua
      echo "Saved to ~/.config/hypr/monitors.lua"
    '';

  in {
    home.packages = [
      pkgs.wdisplays
      pkgs.wlr-randr
      saveMonitors
    ];
  };
}
