{ pkgs, ... }:

{
  # --- Thunderbolt 4 device authorization daemon ---
  services.hardware.bolt.enable = true;

  environment.systemPackages = with pkgs; [
    bolt  # provides boltctl for listing/authorizing TB devices
  ];
}
