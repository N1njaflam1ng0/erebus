{ ... }: {
  flake.nixosModules.keyring = { ... }: {
    services.gnome.gnome-keyring.enable = true;

    # Unlock the login keyring with the SDDM password instead of
    # prompting again after login.
    security.pam.services.sddm.enableGnomeKeyring = true;

    # GUI for browsing/editing stored secrets and SSH/GPG keys.
    programs.seahorse.enable = true;
  };
}
