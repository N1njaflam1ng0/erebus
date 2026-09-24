{self, ...}: {
  flake.nixosModules.sddm = { pkgs, ... }:
  let
    # John Dee and Edward Kelley's Sigillum Dei Aemeth, recoloured to Srcery gold
    # (#FBB829) on hardBlack. Traced from File:Sigilo_Dei_Aemeth.jpg on Wikimedia
    # Commons (CC0, no attribution required); the magick pipeline that produced it
    # is in the plan file, and the result is committed so eval stays offline.
    background = "${self}/assets/backgrounds/Srcery/sigillum-dei-aemeth.png";

    # The colours and every other knob live in _greeter-theme.nix because the
    # lockscreen runs this same theme QML off the same attrset -- see _lock.nix.
    # One copy, or the greeter and the lock drift apart.
    theme = pkgs.sddm-astronaut.override {
      themeConfig = import ./_greeter-theme.nix { inherit background; };
    };
  in {
    services.xserver.enable = true;

    services.displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
        autoNumlock = true;
        enableHidpi = true;

        package = pkgs.kdePackages.sddm;

        # Resolved against Theme.ThemeDir, which the NixOS module hardcodes to
        # /run/current-system/sw/share/sddm/themes — hence systemPackages below.
        theme = "sddm-astronaut-theme";

        # Deliberately lists the theme's QML modules by hand rather than putting
        # the theme package here: sddm-astronaut propagates qtvirtualkeyboard, and
        # anything on this list reaches the greeter's QML import path. The theme's
        # Main.qml loads Components/VirtualKeyboard.qml from an *unconditional*
        # Loader (HideVirtualKeyboard only hides it), so once that import resolves
        # a QtVirtualKeyboard InputPanel registers itself as the input pipeline for
        # the password field and the greeter stops accepting the physical keyboard.
        # Leaving qtvirtualkeyboard off the path makes that import fail, the Loader
        # stays inert, and the field takes keys normally.
        extraPackages = with pkgs.kdePackages; [
          qtdeclarative
          qt5compat
          qtsvg
          qtmultimedia
        ];

        # SDDM already blanks this on Wayland, but the greeter is the one screen
        # that must never lose the keyboard — say it outright.
        settings.General.InputMethod = "";
      };

      defaultSession = "hyprland";
    };

    environment.systemPackages = [ theme ];
  };
}
