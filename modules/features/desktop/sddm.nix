{inputs, ...}: {
  flake.nixosModules.sddm = {pkgs, ...}: {
    # Sigil: the Sigillum Dei Aemeth, drawn live by a Qt plugin + Rust engine.
    # Upstream's module sets sddm.theme = "sigil", puts the theme on
    # systemPackages (share/sddm/themes) and on extraPackages (the plugin's QML
    # import path), and builds it with our pkgs so the plugin matches SDDM's Qt.
    imports = [inputs.sigil-sddm.nixosModules.default];

    programs.sigil-sddm = {
      enable = true;
      # Shared with the lockscreen -- see _lock.nix.
      settings = import ./_greeter-theme.nix;
    };

    services.xserver.enable = true;

    services.displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
        autoNumlock = true;
        enableHidpi = true;

        package = pkgs.kdePackages.sddm;

        # Sigil imports QtQuick.Effects; nothing else outside its own plugin.
        # qtvirtualkeyboard stays off this list: anything here reaches the
        # greeter's QML import path, and a resolvable QtVirtualKeyboard makes an
        # InputPanel the input pipeline and the physical keyboard stops working.
        extraPackages = [pkgs.kdePackages.qtdeclarative];

        # SDDM already blanks this on Wayland, but the greeter is the one screen
        # that must never lose the keyboard — say it outright.
        settings.General.InputMethod = "";
      };

      defaultSession = "hyprland";
    };
  };
}
