{ config, pkgs, inputs, username, ... }:

{
  imports = [
    ./thunar.nix
    inputs.zen-browser.homeModules.default
  ];
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.05";

  # ~/.local/bin holds nixos-publish and the mango helper scripts.
  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

  # Future dark cursor theme. The same theme is also packaged in
  # modules/common.nix (systemPackages) so the greeter and system apps can use
  # it; both take their files from future-cursors/dist, i.e. the exact same
  # store path.
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "Future-cursors";
    size = 32;
    package = pkgs.runCommand "future-cursors" {
      preferLocalBuild = true;
      allowSubstitutes = false;
    } ''
      mkdir -p $out/share/icons
      cp -r ${../future-cursors/dist} $out/share/icons/Future-cursors
    '';
  };

  programs.git.enable = true;

  programs.bash = {
    enable = true;
    shellAliases = {
      willthiswork = "echo This does work!";
    };
    initExtra = ''
      # Local helper scripts: nixos-publish, mango-bar-fullscreen, ...
      case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) export PATH="$HOME/.local/bin:$PATH" ;;
      esac

      # Rebuild; only if it succeeds, snapshot /etc/nixos into ~/nixos-config.
      flakeswitch() {
        local attr
        attr="$(hostname)"
        sudo nixos-rebuild switch --flake "/etc/nixos#''${attr}" "$@" || return $?
        "$HOME/.local/bin/nixos-publish"
      }

      dotnix() {
        case "$1" in
          common)
            sudo hx /etc/nixos/modules/common.nix
            ;;
          host)
            sudo hx /etc/nixos/hosts/laptop/default.nix
            ;;
          home)
            sudo hx /etc/nixos/home/common.nix
            ;;
          flake)
            sudo hx /etc/nixos/flake.nix
            ;;
          *)
            echo "Usage: dotnix [common|host|home|flake]"
            ;;
        esac
      }
    '';
  };
  
  programs.zen-browser = {
    enable = true;
  };
  
  programs.helix = {
    enable = true;
    extraPackages = [ pkgs.nixd ];
    languages = {
      language = [
        {
          name = "nix";
          auto-format = true;
        }
      ];
      language-server = {
        nixd = {
          command = "nixd";
          args = [ "--semantic-tokens=true" ];
          config.nixd =
            let
              # This flake (was previously a copy-pasted path from someone
              # else's machine, /home/brisingr/nixos-config, which made helix
              # report errors for every option lookup).
              myFlake = "(builtins.getFlake (toString /etc/nixos))";
              nixosOpts = "${myFlake}.nixosConfigurations.nixos.options";
            in
            {
              nixpkgs.expr = "import ${myFlake}.inputs.nixpkgs { }";
              formatting.command = [ "nixfmt" ];
              options = {
                nixos.expr = nixosOpts;
                home-manager.expr = "${nixosOpts}.home-manager.users.type.getSubOptions []";
              };
            };
        };
      };
    };
  };

  # programs.rio = {
  #   enable = true;
  #   settings = {
  #     confirm-before-quit = false;
  #     cursor.shape = "beam";
  #     fonts = {
  #       family = "JetBrainsMono Nerd Font";
  #       size = 14;
  #     };
  #     navigation = {
  #       mode = "TopTab"; # or "CollapsedTab", "Breadcrumb", "BottomTab"
  #       hide-if-single = true;
  #     };
  #     renderer = {
  #       backend = "Webgpu";
  #       target-fps = 120;
  #     };
  #     window = {
  #       opacity = 0.95;
  #       decorations = "Disabled";
  #     };
  #   };
  # };

  programs.vesktop = {
    enable = true;
    vencord.settings = {
      autoUpdate = true;
      autoUpdateNotification = true;
      plugins = {
        ClearURLs.enabled = true;
        FixYoutubeEmbeds.enabled = true;
      };
    };
  };
}
