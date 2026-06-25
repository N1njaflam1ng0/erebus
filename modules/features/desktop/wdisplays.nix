{inputs, ...}: {
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

    mirrorToggle = pkgs.writeShellScriptBin "hypr-mirror-toggle" ''
      py=${pkgs.python3}/bin/python3
      rofi=${pkgs.rofi}/bin/rofi
      notify=${pkgs.libnotify}/bin/notify-send
      conf="$HOME/.config/hypr/monitors.conf"
      state="$HOME/.config/hypr/.mirror-state"
      theme="$HOME/.config/rofi/noctalia.rasi"

      # Step-specific overrides referencing noctalia.rasi variables directly —
      # no colors.json needed, so this always follows the active palette.
      _rofi() {
        local border="$1" mesg="$2" prompt="$3"
        $rofi -dmenu -i \
          -theme "$theme" \
          -theme-str "window { border: 2px; border-color: $border; border-radius: 10px; width: 520px; }" \
          -theme-str "prompt { text-color: $border; }" \
          -mesg "$mesg" \
          -p "$prompt"
      }

      # Format monitor list with resolution and refresh rate
      _monitors() {
        ${realHyprctl} -j monitors | $py -c "
      import json, sys
      for m in json.load(sys.stdin):
          n, w, h = m['name'], m['width'], m['height']
          r = round(m['refreshRate'])
          desc = m.get('description', ''').split('(')[0].strip()
          label = f'  {desc}' if desc else '''
          print(f'  {n}   {w}x{h} @ {r}Hz{label}')
      "
      }

      # Build menu: restore entries on top, then active monitors
      MONITORS=$(_monitors)
      RESTORE=""
      if [ -f "$state" ]; then
        while IFS=' ' read -r mon src; do
          [ -n "$mon" ] && RESTORE+="  ''${mon}   unmirroring from ''${src}"$'\n'
        done < "$state"
      fi

      if [ -n "$RESTORE" ]; then
        MENU=$(printf '%s\n%s' "''${RESTORE%$'\n'}" "$MONITORS")
      else
        MENU=$MONITORS
      fi

      # Step 1: pick source (or un-mirror)
      SOURCE_LINE=$(printf '%s\n' "$MENU" | \
        _rofi "@accent" "Pick a monitor to mirror — or select an active mirror to undo it" " Source")
      [ -z "$SOURCE_LINE" ] && exit 0

      # Handle un-mirror
      if [[ "$SOURCE_LINE" == *"unmirroring"* ]]; then
        MON=$(printf '%s' "$SOURCE_LINE" | awk '{print $1}')
        SAVED=$(grep "^monitor=''${MON}," "$conf" 2>/dev/null | grep -v ',mirror' | head -1 | sed 's/^monitor=//')
        if [ -n "$SAVED" ]; then
          ${realHyprctl} keyword monitor "''${SAVED}"
        else
          ${realHyprctl} keyword monitor "''${MON},preferred,auto,1"
        fi
        sed -i "/^''${MON} /d" "$state"
        $notify -u low -t 3000 "Display" "''${MON} restored to extended mode"
        exit 0
      fi

      SOURCE=$(printf '%s' "$SOURCE_LINE" | awk '{print $1}')

      # Step 2: pick target
      TARGET_LINE=$(_monitors | grep -v "''${SOURCE}" | \
        _rofi "@fg" "Mirror ''${SOURCE} onto which monitor?" " Target")
      [ -z "$TARGET_LINE" ] && exit 0
      TARGET=$(printf '%s' "$TARGET_LINE" | awk '{print $1}')

      # Save current layout for restore, then apply mirror
      ${realHyprctl} -j monitors | $py -c "
      import json, sys
      for m in json.load(sys.stdin):
          n, w, h = m['name'], m['width'], m['height']
          r, x, y, s = m['refreshRate'], m['x'], m['y'], m['scale']
          print(f'monitor={n},{w}x{h}@{r},{x}x{y},{s}')
      " > "$conf"
      echo "''${TARGET} ''${SOURCE}" >> "$state"

      ${realHyprctl} keyword monitor "''${TARGET},preferred,0x0,1,mirror,''${SOURCE}"
      $notify -u low -t 3000 "Display" "''${SOURCE}  →  ''${TARGET}  (mirrored)"
    '';
  in {
    home.packages = [
      pkgs.wdisplays
      pkgs.wlr-randr
      saveMonitors
      mirrorToggle
    ];
  };
}
