{...}: {
  flake.nixosModules.flatpak = {pkgs, ...}: {
    services.flatpak.enable = true;

    # NixOS has no declarative option for remotes, so add Flathub once on boot
    systemd.services.flatpak-add-flathub = {
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      path = [pkgs.flatpak];
      serviceConfig.Type = "oneshot";
      script = ''
        flatpak remote-add --if-not-exists flathub \
          https://dl.flathub.org/repo/flathub.flatpakrepo
      '';
    };
  };
}
