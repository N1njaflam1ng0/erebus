{self, ...}: {
  flake.nixosModules.betaflight = {pkgs, ...}: {
    # Betaflight App is a PWA (app.betaflight.com) needing WebSerial/WebUSB -> Chromium only.
    # nixpkgs' native betaflight-configurator (10.10, nwjs) renders a blank window.
    environment.systemPackages = [
      pkgs.chromium
      (pkgs.makeDesktopItem {
        name = "betaflight";
        desktopName = "Betaflight";
        comment = "Configure Betaflight flight controllers";
        exec = "chromium --app=https://app.betaflight.com";
        categories = ["Utility"];
      })
    ];

    # Flight controllers enumerate as /dev/ttyACM* (group dialout)
    users.users.ebbe.extraGroups = ["dialout"];

    services.udev.extraRules = ''
      # STM32 DFU bootloader: allow flashing firmware without root
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", TAG+="uaccess"
      # STM32 virtual COM port: keep ModemManager from grabbing the FC
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="5740", ENV{ID_MM_DEVICE_IGNORE}="1"
    '';
  };
}
