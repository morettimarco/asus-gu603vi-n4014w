{ pkgs, ... }:

{
  # --- Steam ---
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  # --- Gamescope (micro-compositor for games) ---
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  # --- Gamemode (dynamic CPU/GPU optimization during gameplay) ---
  programs.gamemode = {
    enable = true;
    enableRenice = true;
  };

  # --- Controller support ---
  hardware.steam-hardware.enable = true;
  hardware.xpadneo.enable = true;  # Xbox Bluetooth controllers
  hardware.xone.enable = true;     # Xbox wireless dongle

  # --- Gaming packages ---
  environment.systemPackages = with pkgs; [
    mangohud       # FPS/stats overlay
    protonup-qt    # manage Proton-GE versions
    lutris         # multi-platform game launcher
    heroic         # Epic/GOG/Amazon launcher
  ];
}
