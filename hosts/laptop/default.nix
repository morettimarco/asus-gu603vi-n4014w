{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware.nix
  ];

  # --- CachyOS kernel overlay ---
  nixpkgs.overlays = [
    inputs.nix-cachyos-kernel.overlays.default
  ];

  # --- Bootloader: systemd-boot ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- Kernel: CachyOS (gaming-optimized, BORE scheduler) ---
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

  networking.hostName = "zephyrus";

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # --- CachyOS kernel binary cache (avoids compiling from source) ---
  nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
  nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];

  # --- Laptop essentials ---
  services.printing.enable = true;
  services.fwupd.enable = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  system.stateVersion = "25.11";
}
