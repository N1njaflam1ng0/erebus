{ self, ... }: {
  flake.nixosModules.base-system = { pkgs, secrets, ... }: {
    # Needed by GTK applications
    programs.dconf.enable = true;

    # Needed for dynamic linking as NixOs doesn't follow standard file structure
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      glib
      libX11
      libXext
      libXrender
      libICE
      libSM
      libGL
      openssl
    ];

    # Github token for private repos
    nix.settings.access-tokens = "github.com=${secrets.githubToken}";

    # ZRAM swap
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 50;
    };

    # Flakes, store maintenance
    nix.settings.experimental-features = ["nix-command" "flakes"];
    nix.settings.auto-optimise-store = true;
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 10d";
    };

    # Locale / time / console
    time.timeZone = "Europe/Copenhagen";
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.supportedLocales = ["en_US.UTF-8/UTF-8"];
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
    console.keyMap = "dk";

    # Networking & Security
    networking.networkmanager.enable = true;
    services.resolved.enable = true;
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [9001 6000];
    };

    # Audio (PipeWire)
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    # Printing & USB auto-mounting
    services.printing.enable = true;
    services.gvfs.enable = true;
    services.udisks2.enable = true;
    services.devmon.enable = true;

    security.sudo.enable = true;
    programs.fuse.userAllowOther = true;

    # Set time for windows and linux to agree
    time.hardwareClockInLocalTime = false;
    services.timesyncd.enable = true;

    services.upower.enable = true;
  };
}
