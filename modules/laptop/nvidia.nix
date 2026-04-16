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

    # Proprietary driver (best performance for RTX 4070)
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    nvidiaSettings = true;

    # Power management
    powerManagement.enable = true;
    powerManagement.finegrained = true;

    # PRIME offload: Intel iGPU for daily use, RTX 4070 on demand
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;  # provides `nvidia-offload` wrapper
      };
      # TODO: verify with `lspci | grep VGA` on real hardware
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}
