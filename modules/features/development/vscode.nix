{ inputs, ... }: {
  flake.nixosModules.vscode = {...}: {
    nixpkgs.overlays = [inputs.nix-vscode-extensions.overlays.default];
  };

  flake.homeModules.vscode = { pkgs, config, lib, ... }: 
  let
    marketplace = pkgs.vscode-marketplace;

    commonExtensions = with marketplace; [
      bbenoist.nix
      docker.docker
      formulahendry.docker-explorer
      github.copilot-chat
      github.vscode-github-actions
      h5web.vscode-h5web
      hediet.vscode-drawio
      janisdd.vscode-edit-csv
      johnpapa.vscode-cloak
      mechatroner.rainbow-csv
      mikestead.dotenv
      mkhl.direnv
      ms-azuretools.vscode-containers
      ms-azuretools.vscode-docker
      ms-vsliveshare.vsliveshare
      njpwerner.autodocstring
      pkief.material-icon-theme
      james-yu.latex-workshop
      tintinweb.graphviz-interactive-preview
      usernamehw.errorlens
    ];
  in {
    programs.vscode = {
      enable = true;
      package = pkgs.vscode;

      profiles = {
        default = {
          extensions = commonExtensions;
        };

        Go = {
          extensions =
            commonExtensions
            ++ (with marketplace; [
              bradlc.vscode-tailwindcss
              golang.go
              xabikos.javascriptsnippets
            ]);
        };

        Python = {
          extensions =
            commonExtensions
            ++ (with marketplace; [
              ms-python.debugpy
              ms-python.python
              ms-python.vscode-pylance
              ms-python.vscode-python-envs
              ms-toolsai.jupyter
              ms-toolsai.jupyter-keymap
              ms-toolsai.jupyter-renderers
              ms-toolsai.vscode-jupyter-cell-tags
              ms-toolsai.vscode-jupyter-slideshow
            ]);
        };

        Cpp = {
          extensions =
            commonExtensions
            ++ (with marketplace; [
              ms-vscode.cpptools
              ms-vscode.cmake-tools
              ms-vscode.cpptools-themes
            ]);
        };

        Rust = {
          extensions =
            commonExtensions
            ++ (with marketplace; [
              rust-lang.rust-analyzer
              tamasfe.even-better-toml
              fill-labs.dependi
              wgsl-analyzer.wgsl-analyzer
            ])
            ++ [
              pkgs.vscode-extensions.vadimcn.vscode-lldb
            ];
        };
        
        WebGPU = {
          extensions =
            commonExtensions
            ++ (with marketplace; [
              wgsl-analyzer.wgsl-analyzer
              ggsimm.wgsl-literal
              ritwickdey.liveserver
              firefox-devtools.vscode-firefox-debug
              esbenp.prettier-vscode
              formulahendry.auto-rename-tag
              christian-kohler.path-intellisense
              xabikos.javascriptsnippets
              kisstkondoros.vscode-gutter-preview
              cesium.gltf-vscode
            ]);
        };
      };
    };

    home.activation.boostrapVscodeSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Function to force-update a profile from source.
      # $2 is an optional profile-specific settings file, merged over the shared one.
      bootstrap_profile() {
          PROFILE_DIR="$1"
          SETTINGS_OVERLAY="''${2:-}"
          SETTINGS_SOURCE="${./vscode-settings.json}"
          KEYS_SOURCE="${./vscode-keybindings.json}"

          mkdir -p "$PROFILE_DIR"

          # Remove if it's a symlink (Nix default) or just overwrite if it's a file
          if [ -L "$PROFILE_DIR/settings.json" ]; then
              rm -f "$PROFILE_DIR/settings.json"
          fi

          # We overwrite and ensure it is writable by the user
          echo "Updating settings for $PROFILE_DIR"
          if [ -n "$SETTINGS_OVERLAY" ]; then
              ${pkgs.jq}/bin/jq -s ".[0] * .[1]" "$SETTINGS_SOURCE" "$SETTINGS_OVERLAY" > "$PROFILE_DIR/settings.json"
          else
              cp -f "$SETTINGS_SOURCE" "$PROFILE_DIR/settings.json"
          fi
          chmod u+w "$PROFILE_DIR/settings.json"

          # Handle Keybindings
          if [ -L "$PROFILE_DIR/keybindings.json" ]; then
              rm -f "$PROFILE_DIR/keybindings.json"
          fi

          echo "Updating keybindings for $PROFILE_DIR"
          cp -f "$KEYS_SOURCE" "$PROFILE_DIR/keybindings.json"
          chmod u+w "$PROFILE_DIR/keybindings.json"
      }

      # Bootstrap all profiles
      bootstrap_profile "${config.home.homeDirectory}/.config/Code/User"
      bootstrap_profile "${config.home.homeDirectory}/.config/Code/User/profiles/Go"
      bootstrap_profile "${config.home.homeDirectory}/.config/Code/User/profiles/Python"
      bootstrap_profile "${config.home.homeDirectory}/.config/Code/User/profiles/Cpp"
      bootstrap_profile "${config.home.homeDirectory}/.config/Code/User/profiles/Rust"
      bootstrap_profile "${config.home.homeDirectory}/.config/Code/User/profiles/Zig"
      bootstrap_profile "${config.home.homeDirectory}/.config/Code/User/profiles/WebGPU" "${./vscode-settings-webgpu.json}"
    '';
  };
}
