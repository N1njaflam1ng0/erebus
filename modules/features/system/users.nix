{ self, ... }: {
  flake.nixosModules.users = {pkgs, ...}: let
    passwordHash = "$6$U2y05r2gVvq36EQp$xVJzzWt6doCPhatyTMCq5aIgQWLEdwlB4NXhYtsIKewA7MQyVQdR8LVWhU4Dy3S0RDluvEcLT.O/3W58fbMwC.";
  in {
    programs.fish.enable = true;
    
    users.users.ebbe = {
      isNormalUser = true;
      description = "ebbe";
      extraGroups = ["networkmanager" "wheel" "video" "audio"];
      shell = pkgs.fish;
      hashedPassword = passwordHash;
    };
  };
}
