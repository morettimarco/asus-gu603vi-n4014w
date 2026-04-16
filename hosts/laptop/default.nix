{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "zephyrus";

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # --- NVIDIA (hybrid: Intel UHD + RTX 4070) ---
  hardware.graphics.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";    # TODO: verify with `lspci | grep VGA`
      nvidiaBusId = "PCI:1:0:0";   # TODO: verify with `lspci | grep VGA`
    };
  };

  # --- Power management ---
  services.thermald.enable = true;

  services.auto-cpufreq = {
    enable = true;
    settings = {
      battery = {
        governor = "powersave";
        turbo = "never";
      };
      charger = {
        governor = "performance";
        turbo = "auto";
      };
    };
  };

  # --- ROG / ASUS specific ---
  services.asusd = {
    enable = true;
    enableUserService = true;
  };

  # --- Laptop essentials ---
  services.printing.enable = true;
  services.fwupd.enable = true;    # firmware updates
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  system.stateVersion = "25.11";
}
