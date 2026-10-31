{
  description = "NixOS configuration for ASUS ROG Zephyrus G16";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Use release branch for binary cache availability.
    # IMPORTANT: do NOT add inputs.nixpkgs.follows here. The binary cache only
    # ships kernels built against this flake's own pinned nixpkgs; following
    # our nixpkgs changes the derivation hash and forces a local kernel build
    # on every update.
    # See: https://github.com/xddxdd/nix-cachyos-kernel
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
  };

  outputs = { self, nixpkgs, home-manager, nixos-hardware, nix-cachyos-kernel, ... }@inputs:
  let
    sharedModules = [
      ./modules/locale.nix
      ./modules/desktop.nix
      ./modules/audio.nix
      ./modules/networking.nix
      ./modules/packages.nix
      ./modules/users.nix

      # Home Manager (shared across all hosts)
      home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          extraSpecialArgs = { inherit inputs; };
          users.CHANGEME_USERNAME = {
            imports = [
              ./home/common.nix
            ];
          };
        };
      }
    ];

    laptopModules = [
      nixos-hardware.nixosModules.asus-zephyrus-gu603h
      ./modules/gaming.nix
      ./modules/laptop/nvidia.nix
      ./modules/laptop/power.nix
      ./modules/laptop/rog.nix
      ./modules/laptop/thunderbolt.nix
      ./modules/laptop/m4-aura.nix
      # ./modules/laptop/howdy.nix   # optional face login; see README
      ./modules/laptop/kernel-tweaks.nix
    ];
  in
  {
    nixosConfigurations = {

      zephyrus = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = sharedModules ++ laptopModules ++ [
          ./hosts/laptop
        ];
      };

    };
  };
}
