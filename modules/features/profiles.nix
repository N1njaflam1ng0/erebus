{ self, inputs, ... }: {
  flake.homeModules.profile-ebbe = {...}: {
    imports = [
      # Window manager and related packages
      self.homeModules.hyprland

      # Noctalia stuff
      self.homeModules.noctalia
      self.homeModules.bitwarden
      self.homeModules.hypr-screen-mirror
      self.homeModules.nix-monitor

      # Snappy switcher for window switching
      self.homeModules.snappy-switcher

      # Terminal
      self.homeModules.cli
      self.homeModules.gui-terminal
      self.homeModules.shell-aliases

      # Kubernetes client connection to server
      inputs.k3s-cluster.homeModules.ssh
      inputs.k3s-cluster.homeModules.kubernetes-client

      # Everyday use
      self.homeModules.starship
      self.homeModules.git
      self.homeModules.nautilus
      self.homeModules.clipboard
      self.homeModules.appearance
      self.homeModules.development
      self.homeModules.search
      self.homeModules.vscode
      self.homeModules.wdisplays

      # AI tools
      self.homeModules.claude-code
    ];
  };
}
