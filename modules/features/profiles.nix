{ self, ... }: {
  flake.homeModules.profile-ebbe = {...}: {
    imports = [
      # For easy connection to servers
      self.homeModules.ssh

      # Window manager and related packages
      self.homeModules.hyprland
      self.homeModules.noctalia

      # Terminal
      self.homeModules.cli
      self.homeModules.gui-terminal
      self.homeModules.shell-aliases

      # Kubernetes client connection to server
      self.homeModules.kubernetes-client

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
