# The lockscreen. Not a flake-parts module (import-tree skips "/_" paths) but a
# plain function returning the `erebus-lock` package, so helpers.nix can drop it
# straight into `erebus-power lock`.
#
# The lockscreen IS the greeter. qylock's quickshell-lockscreen is an SDDM-theme
# runner: shim/SddmShim.qml fakes SDDM's `sddm`/`userModel`/`sessionModel` context
# objects (auth through Quickshell's PamContext) and ships SddmComponents +
# QtGraphicalEffects shims, so an SDDM theme's Main.qml renders unchanged inside a
# WlSessionLock. Point that at the same sddm-astronaut build the greeter uses and
# the two are the same pixels off the same attrset -- hence no hyprlock, and no
# second copy of the palette to keep in step.
#
# What is ours rather than qylock's: assets/quickshell-lock/lock_shell.qml and the
# generated ThemeConfig.qml. qylock's own shell reads theme.conf with an async
# XMLHttpRequest whose callback never fires under quickshell, leaving `config` {}
# and every colour, font and dimension in the theme undefined. The conf is baked
# into QML at build time instead, so there is no runtime read to fail.
{ pkgs, inputs, self }:
let
  background = "${self}/assets/backgrounds/Srcery/sigillum-dei-aemeth.png";

  # Same attrset as the greeter (sddm.nix), plus what only makes sense on a lock.
  themeConfig = import ./_greeter-theme.nix { inherit background; } // {
    # The shim has no sddm.canPowerOff/canReboot/canSuspend/canHibernate and no
    # suspend()/hibernate(), so SystemButtons.qml would render four buttons that
    # are either invisible (undefined `can*`) or throw on click. Nothing on a lock
    # screen should be able to act on a session you cannot see anyway.
    HideSystemButtons = "true";
  };

  themePkg = pkgs.sddm-astronaut.override { inherit themeConfig; };

  qylockShell = "${inputs.qylock}/quickshell-lockscreen";

  lockSrc = pkgs.runCommand "erebus-lock-src" { } ''
    mkdir -p $out
    cp ${self}/assets/quickshell-lock/lock_shell.qml $out/
    # SddmShim (PAM, userModel, sessionModel) and the SddmComponents /
    # QtGraphicalEffects / QtMultimedia shims an SDDM theme imports. Copied rather
    # than referenced so QML2_IMPORT_PATH and `import "./shim"` both resolve inside
    # one tree. imports/QtGraphicalEffects holds dangling symlinks upstream, so no -L.
    cp -r ${qylockShell}/shim ${qylockShell}/imports $out/
    chmod -R u+w $out

    # Without this, `import "./shim"` does not resolve SddmShim -- an implicit
    # directory import is not enough for quickshell to find the type.
    printf 'module shim\nSddmShim 1.0 SddmShim.qml\n' > $out/shim/qmldir

    # The theme falls back to SDDM's TextConstants wherever a Translate* key is
    # blank, and qylock's stub carries four of the nine strings it reaches for.
    # The two that show are the field placeholders; the rest are here so a later
    # change cannot quietly surface an undefined.
    substituteInPlace $out/imports/SddmComponents/TextConstants.qml \
      --replace-fail 'readonly property string loginFailed: "Try again"' \
        'readonly property string loginFailed: "Try again"; readonly property string userName: "Username"; readonly property string password: "Password"; readonly property string login: "Login"; readonly property string capslockWarning: "Caps Lock is on"; readonly property string shutdown: "Shutdown"; readonly property string reboot: "Restart"; readonly property string suspend: "Suspend"; readonly property string hibernate: "Hibernate"'

    cp -rL ${themePkg}/share/sddm/themes/sddm-astronaut-theme $out/theme

    # LoginForm.qml shows SessionButton unconditionally, and the shim enumerates
    # /usr/share/{wayland-sessions,xsessions}, which on NixOS is nothing -- so it
    # would read "Unknown". A ColumnLayout skips invisible children, so the form
    # closes up around it.
    substituteInPlace $out/theme/Components/LoginForm.qml \
      --replace-fail 'id: sessionSelect' 'id: sessionSelect; visible: false'

    # The config, as QML. Two halves: the theme's own Themes/astronaut.conf for
    # the defaults (FontSize, ScreenPadding, Blur/FullBlur/BlurMax, KeyboardSize
    # and every Translate* live only there, and a key the theme reads but never
    # finds turns into NaN geometry), then the Themes/astronaut.conf.user nixpkgs
    # generates from `themeConfig` -- second, so ours win. `#`/`[General]` lines
    # and the base half's quotes are dropped on the way through.
    cat $out/theme/Themes/astronaut.conf $out/theme/Themes/astronaut.conf.user \
      | awk '
          /^[[:space:]]*[#[]/ || !/=/ { next }
          {
            eq = index($0, "=")
            k = substr($0, 1, eq - 1)
            v = substr($0, eq + 1)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", k)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
            gsub(/"/, "", v)
            gsub(/\\/, "\\\\", v)
            if (k != "") values[k] = v
          }
          END {
            print "// GENERATED from theme.conf -- see modules/features/desktop/_lock.nix"
            print "import QtQuick"
            print ""
            print "QtObject {"
            print "    readonly property var values: ({"
            n = 0
            for (k in values) order[++n] = k
            for (i = 1; i <= n; i++)
              printf "        \"%s\": \"%s\"%s\n", order[i], values[order[i]], (i < n ? "," : "")
            print "    })"
            print "}"
          }
        ' > $out/ThemeConfig.qml
  '';

  # Deliberately not qylock's own qylock-lock wrapper: that one makeWrapper --sets
  # QYLOCK_THEMES_ROOT to its bundled themes, and --set cannot be overridden from
  # outside, so there is no way to hand it a theme of ours.
  qmlPath = pkgs.lib.concatMapStringsSep ":" (p: "${p}/lib/qt-6/qml") (with pkgs.qt6; [
    qtdeclarative
    qt5compat
    qtsvg
    qtmultimedia
  ]);
in
pkgs.writeShellScriptBin "erebus-lock" ''
  # qtvirtualkeyboard stays off this path for the same reason it is off the
  # greeter's extraPackages (see sddm.nix): astronaut's Main.qml loads
  # Components/VirtualKeyboard.qml from an unconditional Loader, and once that
  # import resolves a QtVirtualKeyboard InputPanel registers itself as the input
  # pipeline and the password field stops taking the physical keyboard. Left
  # unresolvable the Loader stays inert and VirtualKeyboardButton hides itself.
  export QML2_IMPORT_PATH="${lockSrc}/imports:${qmlPath}''${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"

  # Picks the WlSessionLock branch over the plain-Window one. QS_TESTING=1 with
  # XDG_SESSION_TYPE=x11 renders the theme in a 1280x720 window instead, which is
  # how to look at it without locking the seat.
  export XDG_SESSION_TYPE="''${XDG_SESSION_TYPE:-wayland}"

  export QS_THEME_PATH=${lockSrc}/theme

  exec ${pkgs.quickshell}/bin/quickshell -p ${lockSrc}/lock_shell.qml "$@"
''
