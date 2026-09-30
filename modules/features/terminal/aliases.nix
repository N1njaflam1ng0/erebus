{...}: {
  flake.homeModules.shell-aliases = {...}: {
    programs.fish.shellAliases = {
      vim = "nvim";
      rebuild = "nh os switch ~/erebus -- --impure";
      update = "nh os switch ~/erebus --update -- --impure";
      clean = "nh clean all --keep 3 && rm -rf ~/.local/share/Trash/*";
      usage = "gdu /";
      store-map = "nix-tree -- /run/current-system";
      roots = "nix-store --gc --print-roots | grep -v '/proc/'";
      dn = "dotnet";
      db = "dotnet build";
      dr = "dotnet run";
      dt = "dotnet test";
    };
  };
}
