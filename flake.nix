{
  description = "Marco's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Do NOT override nixpkgs — patches must match upstream's kernel version
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel";
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
