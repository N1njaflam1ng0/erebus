{ self, inputs, ... }: {
  flake.nixosModules.sddm = { pkgs, ... }:
  let
    # Srcery, lifted slot-for-slot from assets/quickshell/config/Colors.qml so the
    # greeter and the shell cannot drift apart without someone noticing.
    hardBlack    = "#0E0D0C";
    black        = "#121110";
    gray1        = "#1C1B19";
    gray3        = "#312F2C";
    brightBlack  = "#917E6B";
    white        = "#C5B088";
    brightWhite  = "#FCE8C3";
    magenta      = "#E02C6D";  # Colors.qml `accent`
    brightRed    = "#F75341";  # Colors.qml `error`

    # John Dee and Edward Kelley's Sigillum Dei Aemeth, recoloured to Srcery gold
    # (#FBB829) on hardBlack. Traced from File:Sigilo_Dei_Aemeth.jpg on Wikimedia
    # Commons (CC0, no attribution required); the magick pipeline that produced it
    # is in the plan file, and the result is committed so eval stays offline.
    background = "${self}/assets/backgrounds/Srcery/sigillum-dei-aemeth.png";

    theme = pkgs.sddm-astronaut.override {
      themeConfig = {
        Background = background;
        BackgroundColor = hardBlack;
        DimBackgroundColor = hardBlack;
        # Just enough to knock the gold back so the form panel stays the brighter half.
        DimBackground = "0.15";
        CropBackground = "true";

        HeaderText = "erebus";
        Font = "CaskaydiaCove Nerd Font";
        HourFormat = "HH:mm";
        DateFormat = "dddd d MMMM";
        # The shell is square-cornered (Style.bar.radius: 0).
        RoundCorners = "0";

        # Split layout: the form panel takes the left third, the seal gets the rest.
        # (With FormPosition=center the opaque panel sits straight on top of the
        # background and the seal never shows.)
        FormPosition = "left";
        BackgroundHorizontalAlignment = "center";
        HaveFormBackground = "true";
        PartialBlur = "false";
        FormBackgroundColor = gray1;

        HeaderTextColor = brightWhite;
        TimeTextColor = brightWhite;
        DateTextColor = white;

        LoginFieldBackgroundColor = gray3;
        PasswordFieldBackgroundColor = gray3;
        LoginFieldTextColor = brightWhite;
        PasswordFieldTextColor = brightWhite;
        PlaceholderTextColor = brightBlack;
        UserIconColor = white;
        PasswordIconColor = white;

        LoginButtonBackgroundColor = magenta;
        LoginButtonTextColor = black;
        WarningColor = brightRed;

        SystemButtonsIconsColor = brightBlack;
        SessionButtonTextColor = brightBlack;
        VirtualKeyboardButtonTextColor = brightBlack;

        DropdownBackgroundColor = gray1;
        DropdownTextColor = white;
        DropdownSelectedBackgroundColor = gray3;

        HighlightBackgroundColor = gray3;
        HighlightTextColor = brightWhite;
        HighlightBorderColor = gray3;

        HoverUserIconColor = magenta;
        HoverPasswordIconColor = magenta;
        HoverSystemButtonsIconsColor = magenta;
        HoverSessionButtonTextColor = magenta;
        HoverVirtualKeyboardButtonTextColor = magenta;

        HideVirtualKeyboard = "true";
        ForceLastUser = "true";
        PasswordFocus = "true";
      };
    };
  in {
    imports = [ inputs.qylock.nixosModules.default ];

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

        # TEMPORARY, for diagnosing the dead keyboard in the greeter. Logs the
        # Wayland seat and input plumbing to the journal under sddm-greeter-qt6.
        # Read back with:
        #   journalctl -b -1 -t sddm-greeter-qt6 | grep wl_keyboard
        # A known-good trace has, in order:
        #   wl_keyboard#N.keymap(...)   layout delivered to the client
        #   wl_keyboard#N.enter(...)    the greeter window HAS keyboard focus
        #   wl_keyboard#N.key(...)      keystrokes arriving
        # No enter  -> weston never gives the greeter keyboard focus.
        # enter but no key -> the keyboard is not routed to this surface.
        # enter + key -> keys reach Qt and the theme's focus chain drops them.
        # Remove this line once the cause is known.
        settings.General.GreeterEnvironment =
          "WAYLAND_DEBUG=1,QT_LOGGING_RULES=qt.qpa.input*.debug=true";
      };

      defaultSession = "hyprland";
    };

    environment.systemPackages = [ theme ];

    programs.qylock = {
      enable = true;
      theme = "ninja_gaiden";
      # qylock's sddm.enable defaults to *true*, so leaving this out silently hands
      # it services.displayManager.sddm.theme and the astronaut theme above never
      # shows. `theme` then only picks the lockscreen.
      sddm.enable = false;
      # Provides qylock-lock, which `erebus-power lock` invokes.
      quickshell.enable = true;
    };
  };
}
