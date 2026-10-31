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

  # --- Plymouth boot splash ---
  boot.plymouth.enable = true;

  # --- Silent boot (hide kernel messages, show only Plymouth) ---
  boot.consoleLogLevel = 3;

  networking.hostName = "zephyrus";

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # --- CachyOS kernel binary cache (avoids compiling from source) ---
  # The previous endpoint and key were retired after a server compromise
  # (xddxdd/nix-cachyos-kernel#110). Do not trust them again.
  nix.settings.substituters = [ "https://cache.lantian.pub/lantian" ];
  nix.settings.trusted-public-keys = [ "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ=" ];

  # --- Automatic store maintenance ---
  # Weekly GC of generations older than 14 days. systemd-boot keeps the
  # most recent 10 (configurationLimit above), so rollback is always
  # available — this just reclaims disk from long-untouched generations.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
    persistent = true;
  };

  # Hard-link identical files in /nix/store to save disk. Runs daily at
  # 03:45 by default; cheap once the store is already deduped.
  nix.optimise.automatic = true;

  # --- SSD optimization (periodic TRIM) ---
  services.fstrim.enable = true;

  # --- Laptop essentials ---
  services.printing.enable = true;
  services.fwupd.enable = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  system.stateVersion = "25.11";
}
