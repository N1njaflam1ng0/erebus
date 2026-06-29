{ self, ... }: {
  
  flake.homeModules.git = { secrets, pkgs, ... }: {
    programs.git = {
      enable = true;
      lfs.enable = true;
      settings = {
        user = {
          name = "N1njaFlam1ng0";
          email = "ebberoer@gmail.com";
        };
      };
    };

    home.file.".netrc".text = ''
      machine github.com
      login N1njaFlam1ng0
      password ${secrets.githubToken}
    '';
  };
}