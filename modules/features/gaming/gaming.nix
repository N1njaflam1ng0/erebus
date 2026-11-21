{self, ...}: {
  flake.nixosModules.gaming = {pkgs, ...}: {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };

    environment.systemPackages = with pkgs; [
      prismlauncher # Minecraft
      # Risk of Rain 2. Preload uses bare `Buffer`, missing in sandboxed preloads on
      # nixpkgs' newer Electron ("Buffer is not defined" on profile import) -> disable sandbox.
      (r2modman.overrideAttrs (old: {
        postInstall =
          (old.postInstall or "")
          + ''
            substituteInPlace $out/share/r2modman/electron-main.js \
              --replace-fail 'webSecurity:!1}' 'webSecurity:!1,sandbox:!1}'
          '';
      }))
    ];
  };
}
