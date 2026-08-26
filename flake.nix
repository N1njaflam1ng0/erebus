{
  description = "My system configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Core framework
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Wallpaper engine: plays both stills and video, driven by erebus-wallpaper.
    gslapper = {
      url = "github:Nomadcxx/gSlapper";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland";
    split-monitor-workspaces = {
      url = "github:zjeffer/split-monitor-workspaces";
      inputs.hyprland.follows = "hyprland";
    };
    snappy-switcher = {
      # Pinned: upstream 06eb4c5 changed snappy-switcher.service to /usr/bin
      # but its flake.nix postPatch still does --replace-fail "/usr/local",
      # so patchPhase fails. Unpin once upstream fixes it.
      url = "github:OpalAayan/snappy-switcher/0957cd612fadf80fa95034515cb6fa2c163e497e";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    grubermeister.url = "github:N1njaflam1ng0/grubermeister";
    claude-code.url = "github:sadjow/claude-code-nix";
    # sddm
    qylock.url = "github:Darkkal44/qylock";

    k3s-cluster.url = "github:Clusterforgers/k3s-cluster";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake
    {inherit inputs;}
    (inputs.import-tree ./modules);
}
