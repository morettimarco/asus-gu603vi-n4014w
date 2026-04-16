{
  description = "Marco's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Use release branch for binary cache availability
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixos-hardware, nix-cachyos-kernel, noctalia, ... }@inputs:
  let
    sharedModules = [
      ./modules/locale.nix
      ./modules/audio.nix
      ./modules/networking.nix
      ./modules/packages.nix
      ./modules/users.nix
      ./modules/niri.nix

      # Home Manager (shared across all hosts)
      home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          extraSpecialArgs = { inherit inputs; };
          sharedModules = [
            ({ osConfig, ... }: {
              _module.args.hostName = osConfig.networking.hostName;
            })
          ];
          users.marco = {
            imports = [
              ./home/common.nix
              ./home/niri.nix
            ];
          };
        };
      }
    ];

    laptopModules = [
      ./modules/gaming.nix
      ./modules/laptop/nvidia.nix
      ./modules/laptop/power.nix
      ./modules/laptop/rog.nix
      ./modules/laptop/kernel-tweaks.nix
      ./modules/laptop/btrfs-snapshots.nix
    ];
  in
  {
    nixosConfigurations = {

      vm = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit inputs; };
        modules = sharedModules ++ [
          ./hosts/vm
        ];
      };

      laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = sharedModules ++ laptopModules ++ [
          ./hosts/laptop
        ];
      };

    };
  };
}
