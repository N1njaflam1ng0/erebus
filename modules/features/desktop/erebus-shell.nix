# The Quickshell bar lives in its own flake (~/repos/Personal/erebus-shell); this
# only wires it to this repo: Hyprland build, lockscreen, wallpapers, sinks.
{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.erebus-shell = {...}: {
    imports = [inputs.erebus-shell.nixosModules.default];
    programs.erebus-shell.calendar.enable = true;
  };

  # Monitor roles (programs.erebus-shell.outputs) are per host, in hosts/*/home.nix.
  flake.homeModules.erebus-shell = {pkgs, ...}: let
    lock = import ./_lock.nix {inherit pkgs inputs self;};
  in {
    imports = [inputs.erebus-shell.homeModules.default];

    programs.erebus-shell = {
      enable = true;
      hyprlandPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      terminal = "ghostty";
      lockCommand = "${lock}/bin/erebus-lock";
      wallpaper = {
        directory = "${self}/assets/backgrounds";
        default = "animated/large-cherry-blossom-tree.1920x1080.mp4";
      };
      sinks = {
        headphones = "alsa_output.usb-Sony_INZONE_H9___INZONE_H7-00.HiFi__Headphones__sink";
        headset = "alsa_output.usb-Sony_INZONE_H9___INZONE_H7-00.HiFi__Headset__sink";
        hdmi = "alsa_output.pci-0000_01_00.1.hdmi-stereo";
        spdif = "alsa_output.pci-0000_00_1f.3.iec958-stereo";
      };
    };

    # On PATH too, so `erebus-lock` works by hand and from other binds.
    home.packages = [lock];
  };
}
