# PLACEHOLDER — replace with the output of `nixos-generate-config --show-hardware-config`
# when installing on the actual ASUS ROG Zephyrus G16 GU603VI.
#
# Run this on the laptop:
#   nixos-generate-config --show-hardware-config > /etc/nixos/hosts/laptop/hardware.nix

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # TODO: replace with actual UUIDs after install
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/CHANGEME";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/CHANGEME";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
