# Claude Code Setup Instructions

This is a NixOS flake configuration for an ASUS ROG Zephyrus G16 (GU603VI-N4014W) gaming laptop. When asked to set up this system, follow these instructions precisely.

## Hardware

- CPU: Intel Core i7-13620H (13th gen Raptor Lake, 6P + 4E cores, 16 threads)
- GPU: Intel UHD iGPU (`PCI:0:2:0`) + NVIDIA RTX 4070 Max-Q (`PCI:1:0:0`)
- RAM: 48GB DDR4
- WiFi: Intel AX211
- Storage: LUKS2 encryption + ext4

## Autonomous Setup Procedure

### Scenario A: Fresh NixOS install

The primary scenario. The user has installed NixOS from the graphical installer with KDE Plasma 6, LUKS encryption, and ext4, and has booted into the fresh system.

**Step 1: Verify the system state**

```bash
nixos-version
lsblk -f
nix --version
```

**Step 2: Enable flakes (if not already enabled)**

```bash
export NIX_CONFIG="experimental-features = nix-command flakes"
```

Or add to `/etc/nixos/configuration.nix` and rebuild:

```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

**Step 3: Clone this repository**

```bash
nix-shell -p git --run "git clone https://github.com/morettimarco/asus-gu603vi-n4014w.git /home/<username>/nixos-config"
```

**Step 4: Update hardware.nix with real UUIDs**

The file `hosts/laptop/hardware.nix` has `CHANGEME` placeholders. The simplest approach is to replace it entirely:

```bash
nixos-generate-config --show-hardware-config > /home/<username>/nixos-config/hosts/laptop/hardware.nix
```

**Alternative:** Edit the placeholders manually. List all block devices to find UUIDs:

```bash
sudo blkid
```

Note: do NOT use `blkid | grep crypto_LUKS` — it may return nothing depending on partition labels. Instead, read the full `blkid` output and identify partitions by their `TYPE` field:
- `TYPE="vfat"` with EFI/ESP label → **ESP UUID** (replace `CHANGEME-ESP-UUID`)
- `TYPE="crypto_LUKS"` → **LUKS UUID** (replace all 3 instances of `CHANGEME-LUKS-UUID`)

Also run `nixos-generate-config --show-hardware-config` and add any missing kernel modules to `boot.initrd.availableKernelModules`.

**Step 4b: Update username and personal details**

The configuration files contain `CHANGEME` placeholders for the username. Replace them with the actual user's details:

- `modules/users.nix` — replace `CHANGEME_USERNAME` and `CHANGEME_DESCRIPTION`
- `home/common.nix` — replace `CHANGEME_USERNAME`, `CHANGEME_FULL_NAME`, and `CHANGEME_EMAIL`
- `flake.nix` — replace `users.CHANGEME_USERNAME`

**Step 5: Verify GPU bus IDs**

```bash
lspci | grep VGA
```

Expected: Intel at `00:02.0` and NVIDIA at `01:00.0`. If different, update `modules/laptop/nvidia.nix`:
- `intelBusId = "PCI:0:2:0"` (format: `PCI:bus:device:function`, hex to decimal)
- `nvidiaBusId = "PCI:1:0:0"`

**Step 6: Test build**

```bash
cd /home/<username>/nixos-config
nix build .#nixosConfigurations.zephyrus.config.system.build.toplevel --no-link
```

The CachyOS kernel compiles from source (~15-30 min on first build).

**Step 7: Apply and reboot**

Use `boot` (safer than `switch` — activates on reboot only):

```bash
sudo nixos-rebuild boot --flake .#zephyrus
sudo reboot
```

**Step 8: Post-reboot verification**

```bash
uname -r                                    # cachyos kernel
nvidia-smi                                  # RTX 4070 + driver version
nvidia-offload glxinfo | grep renderer      # NVIDIA
glxinfo | grep renderer                     # Intel (iGPU default)
asusctl profile -l                          # Quiet/Balanced/Performance
supergfxctl -g                              # GPU mode
zramctl                                     # ~12GB lz4 zram
systemctl status auto-cpufreq thermald asusd supergfxd
wpctl status | head -5                      # PipeWire active
sensors                                     # Temperatures
cat /proc/sys/vm/max_map_count              # 1048576
```

**Step 9: Set user password**

```bash
sudo passwd <username>
```

### Scenario B: Existing NixOS install (different hardware.nix)

If the system already has NixOS but a different disk layout than expected:

1. Follow Steps 1-3 above
2. Replace `hardware.nix` entirely: `nixos-generate-config --show-hardware-config > hosts/laptop/hardware.nix`
3. Continue from Step 5

### Scenario C: Reinstalling from a running system

Migrating to a new drive:

1. Partition and format the target drive (LUKS + ext4)
2. Mount under `/mnt`
3. Copy config: `cp -r /home/<username>/nixos-config /mnt/home/<username>/nixos-config`
4. Update `hardware.nix` with new UUIDs
5. Run: `sudo nixos-install --flake /mnt/home/<username>/nixos-config#zephyrus --root /mnt`
6. Reboot into the new drive

## Troubleshooting

- **NVIDIA driver fails to load after reboot:** Boot previous generation from systemd-boot menu.
- **CachyOS kernel won't build:** In `hosts/laptop/default.nix`, temporarily replace with `boot.kernelPackages = pkgs.linuxPackages_latest;` and remove the CachyOS overlay.
- **supergfxd conflicts with PRIME offload:** Remove `./modules/laptop/rog.nix` from `laptopModules` in `flake.nix`.
- **Screen brightness not working:** Check `ls /sys/class/backlight/`. Kernel params in `modules/laptop/kernel-tweaks.nix` handle this.
- **No audio:** Verify PipeWire: `systemctl --user status pipewire`. Check `wpctl status`.
- **Build takes very long:** Normal for first build (CachyOS kernel compiles from source).

## Configuration Overview

| Module | Purpose |
|--------|---------|
| `flake.nix` | Entry point, inputs (nixpkgs-unstable, home-manager, nixos-hardware, cachyos-kernel) |
| `hosts/laptop/default.nix` | Bootloader (systemd-boot), CachyOS kernel, flakes, bluetooth, fwupd |
| `hosts/laptop/hardware.nix` | Disk layout (LUKS+ext4 UUIDs), kernel modules, Intel microcode |
| `modules/gaming.nix` | Steam, Gamescope, Gamemode, MangoHud, Lutris, Heroic, ProtonUp-Qt, Xbox controllers |
| `modules/laptop/nvidia.nix` | NVIDIA open drivers, PRIME offload (Intel primary, RTX on demand) |
| `modules/laptop/power.nix` | zram (12GB, lz4), auto-cpufreq, thermald |
| `modules/laptop/rog.nix` | asusd (fan/LED/battery), supergfxd (GPU switching) |
| `modules/laptop/kernel-tweaks.nix` | Gaming sysctls, backlight params, split_lock_detect=off |
| `modules/desktop.nix` | KDE Plasma 6 + SDDM |
| `modules/audio.nix` | PipeWire + ALSA 32-bit |
| `modules/locale.nix` | Europe/Rome, en_US.UTF-8, Italian keyboard |
| `modules/networking.nix` | NetworkManager |
| `modules/packages.nix` | vim, wget, git, claude-code, firefox, pciutils, sensors, nvtop, htop |
| `modules/users.nix` | User account (wheel, networkmanager, gamemode groups) |
| `home/common.nix` | Home Manager: git, starship prompt, btop |
