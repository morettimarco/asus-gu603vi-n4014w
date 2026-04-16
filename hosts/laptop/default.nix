{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware.nix
  ];

  # --- CachyOS kernel overlay ---
  nixpkgs.overlays = [
    inputs.nix-cachyos-kernel.overlays.default
  ];

  # --- Bootloader: Limine ---
  boot.loader.limine = {
    enable = true;
    maxGenerations = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # --- Kernel: CachyOS (gaming-optimized, BORE scheduler) ---
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

  networking.hostName = "zephyrus";

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # --- Laptop essentials ---
  services.printing.enable = true;
  services.fwupd.enable = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  system.stateVersion = "25.11";
}
