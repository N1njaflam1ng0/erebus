# The lockscreen. Not a flake-parts module (import-tree skips "/_" paths) but a
# plain function returning the `erebus-lock` package, so helpers.nix can drop it
# straight into `erebus-power lock`.
#
# The lockscreen IS the greeter. qylock's quickshell-lockscreen is an SDDM-theme
# runner: shim/SddmShim.qml fakes SDDM's `sddm`/`userModel`/`sessionModel` context
# objects (auth through Quickshell's PamContext), so an SDDM theme's Main.qml
# renders unchanged inside a WlSessionLock. Point that at the same Sigil build the
# greeter uses, off the same settings -- hence no hyprlock, and no second copy of
# the look to keep in step.
#
# What is ours rather than qylock's: assets/quickshell-lock/lock_shell.qml and the
# generated ThemeConfig.qml. qylock's own shell reads theme.conf with an async
# XMLHttpRequest whose callback never fires under quickshell, leaving `config` {}.
# The conf is baked into QML at build time instead, so there is no runtime read
# to fail.
{
  pkgs,
  inputs,
  self,
}: let
  # The same call upstream's NixOS module makes (see sddm.nix), with the same
  # settings, so the plugin derivation is shared and built against pkgs' Qt --
  # the Qt quickshell runs, which a QML plugin has to match.
  themePkg = pkgs.callPackage "${inputs.sigil-sddm}/nix/package.nix" {
    settings = import ./_greeter-theme.nix;
  };

  qylockShell = "${inputs.qylock}/quickshell-lockscreen";

  lockSrc = pkgs.runCommand "erebus-lock-src" {} ''
    mkdir -p $out
    cp ${self}/assets/quickshell-lock/lock_shell.qml $out/
    # SddmShim (PAM, userModel, sessionModel). Sigil imports none of qylock's
    # SddmComponents / QtGraphicalEffects shims, so imports/ is left behind.
    cp -r ${qylockShell}/shim $out/
    chmod -R u+w $out

    # Without this, `import "./shim"` does not resolve SddmShim -- an implicit
    # directory import is not enough for quickshell to find the type.
    printf 'module shim\nSddmShim 1.0 SddmShim.qml\n' > $out/shim/qmldir

    cp -rL ${themePkg}/share/sddm/themes/sigil $out/theme
    chmod -R u+w $out/theme

    # Two corners that have nothing to do on a lock. The session chooser would
    # read "Unknown": the shim enumerates /usr/share/{wayland-sessions,xsessions},
    # which on NixOS is nothing. PowerBar binds sddm.canSuspend/canReboot/
    # canPowerOff, which the shim does not have, and a lock screen should not be
    # able to act on a session you cannot see anyway.
    substituteInPlace $out/theme/Main.qml \
      --replace-fail 'id: session' 'id: session; visible: false' \
      --replace-fail 'PowerBar {' 'PowerBar { visible: false;'

    # theme.conf, as QML: `#`/`[General]` lines and quotes dropped on the way
    # through. Main.qml's conf() falls back to the same values, so this only
    # matters once theme.conf and those fallbacks disagree.
    awk '
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
        ' $out/theme/theme.conf > $out/ThemeConfig.qml
  '';

  # Deliberately not qylock's own qylock-lock wrapper: that one makeWrapper --sets
  # QYLOCK_THEMES_ROOT to its bundled themes, and --set cannot be overridden from
  # outside, so there is no way to hand it a theme of ours.
  #
  # QtQuick.Effects (PasswordSigil, FallbackFigure) and the `Sigil` plugin, which
  # the theme package links at lib/qt-6. Without the plugin the theme still
  # works, but shows the still instead of the live figure.
  qmlPath = pkgs.lib.concatMapStringsSep ":" (p: "${p}/lib/qt-6/qml") [
    pkgs.qt6.qtdeclarative
    themePkg
  ];
in
  pkgs.writeShellScriptBin "erebus-lock" ''
    # qtvirtualkeyboard stays off this path for the same reason it is off the
    # greeter's extraPackages (see sddm.nix).
    export QML2_IMPORT_PATH="${qmlPath}''${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"

    # Picks the WlSessionLock branch over the plain-Window one. QS_TESTING=1 with
    # XDG_SESSION_TYPE=x11 renders the theme in a 1280x720 window instead, which is
    # how to look at it without locking the seat.
    export XDG_SESSION_TYPE="''${XDG_SESSION_TYPE:-wayland}"

    export QS_THEME_PATH=${lockSrc}/theme

    exec ${pkgs.quickshell}/bin/quickshell -p ${lockSrc}/lock_shell.qml "$@"
  ''
