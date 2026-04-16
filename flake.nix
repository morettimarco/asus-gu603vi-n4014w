{
  description = "Marco's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
  let
    sharedModules = [
      ./modules/locale.nix
      ./modules/desktop.nix
      ./modules/audio.nix
      ./modules/networking.nix
      ./modules/packages.nix
      ./modules/users.nix
    ];
  in
  {
    nixosConfigurations = {

      vm = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = sharedModules ++ [
          ./hosts/vm
        ];
      };

      laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = sharedModules ++ [
          ./hosts/laptop
        ];
      };

    };
  };
}
