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
  # The previous endpoint and key were retired after a server compromise
  # (xddxdd/nix-cachyos-kernel#110). Do not trust them again.
  nix.settings.substituters = [ "https://cache.lantian.pub/lantian" ];
  nix.settings.trusted-public-keys = [ "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ=" ];

  # --- SSD optimization (periodic TRIM) ---
  services.fstrim.enable = true;

  # --- Laptop essentials ---
  services.printing.enable = true;
  services.fwupd.enable = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  system.stateVersion = "25.11";
}
