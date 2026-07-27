{self, ...}: {
  flake.homeModules.shell-aliases = {pkgs, ...}: {
    programs.fish.shellAliases = let
      flakePath = "$HOME/erebus";
    in {
      vim = "nvim";
      rebuild = "nh os switch ~/erebus -- --impure";
      update = "nh os switch ~/erebus --update -- --impure";
      clean = "nh clean all --keep 3 && rm -rf ~/.local/share/Trash/*";
      usage = "gdu /";
      store-map = "nix-tree -- /run/current-system";
      roots = "nix-store --gc --print-roots | grep -v '/proc/'";
      hms = "home-manager switch --flake ${flakePath}#$(hostname)";
      dn = "dotnet";
      db = "dotnet build";
      dr = "dotnet run";
      dt = "dotnet test";
      ssh = "kitten ssh";
    };
  };
}
