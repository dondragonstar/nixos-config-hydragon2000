{
  description = "NixOS configuration";

  inputs = {

    nixpkgs.url = "nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    mangowm = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      # One NixOS configuration per folder under hosts/.
      # `system` can be overridden per host if the second machine is not
      # x86_64-linux.
      mkHost = { hostDir, system ? "x86_64-linux" }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./modules/common.nix
            (./hosts + "/${hostDir}/default.nix")
            inputs.mangowm.nixosModules.mango
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs; };
                users.hydragon2000 = import ./home/common.nix;
                backupFileExtension = "backup";
              };
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        # Keep the old attribute name so `--flake /etc/nixos#nixos` and the
        # `flakeswitch` alias keep working unchanged.
        nixos = mkHost { hostDir = "laptop"; };

        # After installing NixOS on the second PC and copying its generated
        # hardware-configuration.nix into hosts/desktop/, uncomment this:
        # desktop = mkHost { hostDir = "desktop"; };
      };
    };
}
