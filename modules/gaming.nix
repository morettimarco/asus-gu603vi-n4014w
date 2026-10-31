{ pkgs, ... }:

{
  # --- Steam ---
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
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

  # --- uinput: lets Steam synthesize keyboard/mouse from controllers without
  # going through KDE's RemoteDesktop portal on Wayland. Without this, every
  # game that uses Steam Input triggers a "Remote Control" approval dialog on
  # each launch. Membership in the `uinput` and `input` groups is granted in
  # modules/users.nix; log out/in after enabling for the first time.
  hardware.uinput.enable = true;

  # --- ntsync: native NT-style sync primitives for Wine/Proton (Linux 6.14+) ---
  # CachyOS kernel qualifies. Modern Wine ≥ 9 / Proton ≥ 9 use /dev/ntsync
  # automatically when present, replacing eventfd-based esync/fsync emulation.
  boot.kernelModules = [ "ntsync" ];
  services.udev.extraRules = ''
    KERNEL=="ntsync", MODE="0660", TAG+="uaccess"
    KERNEL=="uinput", GROUP="uinput", MODE="0660", OPTIONS+="static_node=uinput"
  '';

  # --- Gaming packages ---
  environment.systemPackages = with pkgs; [
    mangohud       # FPS/stats overlay
    protonup-qt    # manage Proton-GE versions
    lutris         # multi-platform game launcher
    heroic         # Epic/GOG/Amazon launcher
    glmark2        # OpenGL benchmark
    vulkan-tools   # vulkaninfo, vkcube
  ];
}
