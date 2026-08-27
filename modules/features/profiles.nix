{ self, inputs, ... }: {
  flake.homeModules.profile-ebbe = {...}: {
    imports = [
      # Window manager and related packages
      self.homeModules.hyprland

      # Quickshell desktop shell
      self.homeModules.quickshell
      self.homeModules.quickshell-helpers
      self.homeModules.calendar
      self.homeModules.wallpaper
      self.homeModules.clipboard-tools
      self.homeModules.monitors

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
      self.homeModules.icons
      self.homeModules.development
      self.homeModules.search
      self.homeModules.vscode
      self.homeModules.wdisplays
      self.homeModules.thunderbird

      # AI tools
      self.homeModules.claude-code
    ];
  };
}
