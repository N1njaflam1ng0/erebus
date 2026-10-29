{ self, ... }: {
  flake.nixosModules.ofmc = { pkgs, ... }: let
    # Prebuilt binary from the course zip (ofmc2024.2). patchelf/strip both make
    # it segfault, so run it untouched through glibc's loader with gmp added.
    ofmc = pkgs.stdenvNoCC.mkDerivation {
      pname = "ofmc";
      version = "2024.2";
      src = ./_ofmc/ofmc;
      dontUnpack = true;
      dontStrip = true;
      dontPatchELF = true;
      installPhase = ''
        install -Dm755 $src $out/libexec/ofmc
        mkdir -p $out/bin
        cat > $out/bin/ofmc <<SH
        #!${pkgs.runtimeShell}
        export LD_LIBRARY_PATH=${pkgs.gmp}/lib\''${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}
        exec ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 $out/libexec/ofmc "\$@"
        SH
        chmod +x $out/bin/ofmc
      '';
    };
  in {
    environment.systemPackages = [ ofmc ];
  };
}
