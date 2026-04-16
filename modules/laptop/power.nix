{ lib, ... }:

{
  # --- zram (compressed RAM swap, no disk swap) ---
  zramSwap = {
    enable = true;
    algorithm = "lz4";
    memoryPercent = 25;  # ~12GB on 48GB RAM — plenty as emergency swap
  };

  swapDevices = lib.mkForce [];  # no disk swap

  # --- CPU frequency scaling ---
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

  # --- Disable power-profiles-daemon (conflicts with auto-cpufreq) ---
  services.power-profiles-daemon.enable = false;

  # --- Intel thermal management ---
  services.thermald.enable = true;
}
