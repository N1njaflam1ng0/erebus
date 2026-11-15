{ self, ... }: {
  flake.nixosModules.gaming = { pkgs, ... }: {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };

    environment.systemPackages = with pkgs; [
      prismlauncher # Minecraft
      r2modman # Risk of Rain 2
    ];
  };
}
