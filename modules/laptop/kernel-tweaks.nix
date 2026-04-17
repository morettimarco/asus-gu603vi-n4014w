{ ... }:

{
  boot.kernel.sysctl = {
    # Required by many modern games and Proton (default 65530 is too low)
    "vm.max_map_count" = 1048576;

    # With 48GB RAM, strongly prefer keeping data in memory
    "vm.swappiness" = 5;

    # Reduce inode/dentry cache reclaim pressure
    "vm.vfs_cache_pressure" = 50;
  };

  boot.kernelParams = [
    # Prevent performance penalty from split-lock detection (games are frequent offenders)
    "split_lock_detect=off"

    # Disable watchdog timers (slight power saving, less interrupt overhead)
    "nowatchdog"

    # Explicit NVIDIA DRM modesetting (belt-and-suspenders with hardware.nvidia.modesetting)
    "nvidia-drm.modeset=1"

    # Backlight: use Intel i915 DPCD for brightness, disable NVIDIA handler (prevents conflicts)
    "i915.enable_dpcd_backlight=1"
    "nvidia.NVreg_EnableBacklightHandler=0"
    "nvidia.NVReg_RegistryDwords=EnableBrightnessControl=0"
  ];
}
