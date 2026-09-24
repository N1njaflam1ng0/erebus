{...}: {
  flake.homeModules.nautilus = { pkgs, ... }: {
    # No gvfs here: services.gvfs.enable in base-system.nix already installs it
    # system-wide. These are the thumbnailers Nautilus looks up at runtime.
    home.packages = with pkgs; [
      nautilus
      ffmpegthumbnailer  
      webp-pixbuf-loader 
      libheif            
    ];

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
        "application/pdf" = [ "org.kde.okular.desktop" ];
      };
    };
  };
}