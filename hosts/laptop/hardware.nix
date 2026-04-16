# PLACEHOLDER — replace with output of `nixos-generate-config --show-hardware-config`
# after partitioning the ASUS ROG Zephyrus G16 GU603VI.
#
# Intended partition layout:
#   /dev/nvme0n1p1  — 4GB ESP (FAT32) → /boot
#   /dev/nvme0n1p2  — rest of 4TB NVMe → LUKS → Btrfs
#
# Btrfs subvolumes (create during install):
#   btrfs subvolume create /mnt/@
#   btrfs subvolume create /mnt/@home
#   btrfs subvolume create /mnt/@nix
#   btrfs subvolume create /mnt/@snapshots
#   btrfs subvolume create /mnt/@var_log

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # --- LUKS encryption ---
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/CHANGEME-LUKS-UUID";
    allowDiscards = true;       # TRIM for NVMe performance
    bypassWorkqueues = true;    # NVMe performance optimization
  };

  # --- Btrfs subvolumes ---
  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@" "compress=zstd:1" "noatime" "ssd" "discard=async" ];
  };

  fileSystems."/home" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd:1" "noatime" "ssd" "discard=async" ];
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@nix" "compress=zstd:1" "noatime" "ssd" "discard=async" "nodev" "nosuid" ];
  };

  fileSystems."/.snapshots" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@snapshots" "compress=zstd:1" "noatime" "ssd" "discard=async" ];
  };

  fileSystems."/var/log" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@var_log" "compress=zstd:1" "noatime" "ssd" "discard=async" ];
    neededForBoot = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/CHANGEME-ESP-UUID";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];  # using zram instead

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
