{...}: {
  # programs.thunderbird.enable installs programs.thunderbird.package, so there
  # is no separate home.packages entry.
  flake.homeModules.thunderbird = { ... }: {
    programs.thunderbird = {
      enable = true;
    };
  };
}