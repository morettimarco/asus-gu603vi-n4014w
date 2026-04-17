{ config, ... }:

{
  # --- Graphics (32-bit support required for Steam/Proton) ---
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # --- NVIDIA driver ---
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;

    # Open kernel modules (recommended for Ada Lovelace / RTX 4070 Max-Q)
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Power management
    powerManagement.enable = true;
    powerManagement.finegrained = true;

    # PRIME offload: Intel iGPU for daily use, RTX 4070 Max-Q on demand
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;  # provides `nvidia-offload` wrapper
      };
      # Verified with lspci on actual hardware
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}
