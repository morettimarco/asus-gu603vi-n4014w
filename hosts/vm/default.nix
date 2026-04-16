{ pkgs, ... }:

{
  imports = [
    ./hardware.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos-vm";

  # --- GPU acceleration (VirGL via virtio-gpu) ---
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      virglrenderer
    ];
  };

  # Printing (VM convenience)
  services.printing.enable = true;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.11";
}
