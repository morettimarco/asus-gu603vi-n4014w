# Hardware configuration for ASUS ROG Zephyrus G16 GU603VI
#
# IMPORTANT: Replace the CHANGEME placeholders with your actual UUIDs.
# Run these commands to get them:
#
#   blkid <your-luks-partition> -s UUID -o value   → LUKS UUID
#   blkid <your-esp-partition>  -s UUID -o value   → ESP UUID
#
# If you don't use LUKS, replace hardware.nix entirely with the output of:
#   nixos-generate-config --show-hardware-config

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "vmd" "nvme" "uas" "usbhid" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # --- LUKS encryption ---
  boot.initrd.luks.devices."luks-CHANGEME-LUKS-UUID" = {
    device = "/dev/disk/by-uuid/CHANGEME-LUKS-UUID";
  };

  # --- Root filesystem (ext4 on LUKS) ---
  fileSystems."/" = {
    device = "/dev/mapper/luks-CHANGEME-LUKS-UUID";
    fsType = "ext4";
  };

  # --- Boot partition ---
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/CHANGEME-ESP-UUID";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
