# Claude Code Setup Instructions

This is a NixOS flake configuration for an ASUS ROG Zephyrus G16 (GU603VI-N4014W) gaming laptop. When asked to set up this system, follow these instructions precisely.

## Hardware

- CPU: Intel Core i7-13620H (13th gen Raptor Lake, 6P + 4E cores, 16 threads)
- GPU: Intel UHD iGPU (`PCI:0:2:0`) + NVIDIA RTX 4070 Max-Q (`PCI:1:0:0`)
- RAM: 48GB DDR4
- WiFi: Intel AX211
- Target storage: 4TB NVMe with LUKS2 encryption + Btrfs subvolumes

## Autonomous Setup Procedure

### Scenario A: Fresh NixOS install (target NVMe with LUKS+Btrfs)

This is the primary scenario. The user has just installed NixOS from the installer and booted into a minimal system. The NVMe should already be partitioned with LUKS+Btrfs subvolumes.

**Step 1: Verify the system state**

```bash
# Check we're on NixOS
nixos-version
# Check disk layout
lsblk -f
# Check if flakes are enabled
nix --version
```

**Step 2: Enable flakes (if not already enabled)**

If flakes are not enabled, temporarily enable them for the rebuild:

```bash
export NIX_CONFIG="experimental-features = nix-command flakes"
```

Or add to the current system config and rebuild first:

```bash
# Add to /etc/nixos/configuration.nix:
#   nix.settings.experimental-features = [ "nix-command" "flakes" ];
# Then: sudo nixos-rebuild switch
```

**Step 3: Clone this repository**

```bash
nix-shell -p git --run "git clone https://github.com/morettimarco/asus-gu603vi-n4014w.git /home/marco/nixos-config"
```

**Step 4: Update hardware.nix with real UUIDs**

The file `hosts/laptop/hardware.nix` has `CHANGEME` placeholders. Replace them:

```bash
# Get the LUKS partition UUID (NOT the mapper UUID)
blkid /dev/nvme0n1p2 -s UUID -o value
# Get the ESP UUID
blkid /dev/nvme0n1p1 -s UUID -o value
```

Edit `hosts/laptop/hardware.nix`:
- Replace `CHANGEME-LUKS-UUID` with the UUID from `/dev/nvme0n1p2`
- Replace `CHANGEME-ESP-UUID` with the UUID from `/dev/nvme0n1p1`

Also run `nixos-generate-config --show-hardware-config` and check if there are any additional kernel modules in `boot.initrd.availableKernelModules` that aren't already listed. Add any missing ones.

**IMPORTANT:** If the system uses LUKS+Btrfs, uncomment `./modules/laptop/btrfs-snapshots.nix` in `laptopModules` in `flake.nix`. If the system uses ext4 or any non-Btrfs filesystem, it MUST stay commented out or the system will crash during activation.

**Step 5: Verify GPU bus IDs**

```bash
nix-shell -p pciutils --run "lspci -nn | grep VGA"
```

Expected: Intel at `00:02.0` and NVIDIA at `01:00.0`. If different, update `modules/laptop/nvidia.nix`:
- `intelBusId = "PCI:0:2:0"` — format is `PCI:bus:device:function` (convert hex to decimal)
- `nvidiaBusId = "PCI:1:0:0"`

**Step 6: Build (test without applying)**

```bash
cd /home/marco/nixos-config
nix build .#nixosConfigurations.laptop.config.system.build.toplevel --no-link
```

This will take a while (CachyOS kernel compiles from source). If it fails, fix the error and retry. Common issues:
- Missing UUID: check hardware.nix
- Kernel module build failure: try `pkgs.linuxPackages_latest` instead of CachyOS as a fallback in `hosts/laptop/default.nix`

**Step 7: Apply the configuration**

```bash
cd /home/marco/nixos-config
sudo nixos-rebuild switch --flake .#laptop
```

**Step 8: Reboot**

A reboot is required to load the CachyOS kernel and NVIDIA drivers.

```bash
sudo reboot
```

**Step 9: Post-reboot verification**

Run these checks and report results:

```bash
uname -r                                    # Should show 7.x.x-cachyos
nvidia-smi                                  # Should show RTX 4070, driver version
nvidia-offload glxinfo | grep renderer      # Should show NVIDIA
glxinfo | grep renderer                     # Should show Intel (iGPU default)
asusctl profile list                        # Should show Quiet/Balanced/Performance
asusctl profile get                         # Current profile
supergfxctl -s                              # GPU modes available
zramctl                                     # Should show ~12GB lz4 zram
systemctl status auto-cpufreq thermald asusd supergfxd  # All should be active
wpctl status | head -5                      # PipeWire active
sensors                                     # CPU/GPU temperatures
cat /proc/sys/vm/max_map_count              # Should be 1048576
snapper -c root list                        # Btrfs snapshots working
```

**Step 10: Set user password**

```bash
sudo passwd marco
```

### Scenario B: Existing NixOS install (non-LUKS, non-Btrfs)

If the system is running on a simple ext4 partition (e.g., temporary test drive):

1. Follow Steps 1-3 above
2. Instead of editing hardware.nix, **replace it entirely** with the output of:
   ```bash
   nixos-generate-config --show-hardware-config
   ```
3. Ensure `./modules/laptop/btrfs-snapshots.nix` stays commented out in `laptopModules` in `flake.nix` (Snapper requires Btrfs — enabling it on ext4 will crash the system)
4. Continue from Step 5

### Scenario C: Reinstalling from a running system

If migrating from one drive to another while the system is running:

1. Partition and format the target drive (LUKS + Btrfs subvolumes as described in README.md)
2. Mount all subvolumes under `/mnt`
3. Copy the config: `cp -r /home/marco/nixos-config /mnt/home/marco/nixos-config`
4. Update `hardware.nix` with new UUIDs
5. Run: `sudo nixos-install --flake /mnt/home/marco/nixos-config#laptop --root /mnt`
6. Reboot into the new drive

## Partition Layout Reference

For the 4TB NVMe (`/dev/nvme0n1`):

```
nvme0n1p1  — 4GB    — FAT32 — ESP (/boot)
nvme0n1p2  — ~3.6TB — LUKS2 → Btrfs
  @          → /
  @home      → /home
  @nix       → /nix
  @snapshots → /.snapshots
  @var_log   → /var/log
```

Partitioning commands (run from NixOS installer):

```bash
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 4GiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart primary 4GiB 100%
mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1
cryptsetup luksFormat --type luks2 /dev/nvme0n1p2
cryptsetup open /dev/nvme0n1p2 cryptroot
mkfs.btrfs -L nixos /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@var_log
umount /mnt
mount -o subvol=@,compress=zstd:1,noatime,ssd,discard=async /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{home,nix,.snapshots,var/log,boot}
mount -o subvol=@home,compress=zstd:1,noatime,ssd,discard=async /dev/mapper/cryptroot /mnt/home
mount -o subvol=@nix,compress=zstd:1,noatime,ssd,discard=async,nodev,nosuid /dev/mapper/cryptroot /mnt/nix
mount -o subvol=@snapshots,compress=zstd:1,noatime,ssd,discard=async /dev/mapper/cryptroot /mnt/.snapshots
mount -o subvol=@var_log,compress=zstd:1,noatime,ssd,discard=async /dev/mapper/cryptroot /mnt/var/log
mount /dev/nvme0n1p1 /mnt/boot
```

## Troubleshooting

- **NVIDIA driver fails to load after reboot:** Boot previous generation from systemd-boot menu. The old config with Nouveau is still available as a fallback.
- **CachyOS kernel won't build:** In `hosts/laptop/default.nix`, temporarily replace the kernel line with `boot.kernelPackages = pkgs.linuxPackages_latest;` and remove the CachyOS overlay.
- **supergfxd conflicts with PRIME offload:** Disable supergfxd by removing `./modules/laptop/rog.nix` from `laptopModules` in `flake.nix`. PRIME offload works independently.
- **Screen brightness not working:** The kernel params in `modules/laptop/kernel-tweaks.nix` handle this (`i915.enable_dpcd_backlight=1`). If still broken, check `ls /sys/class/backlight/`.
- **No audio:** Verify PipeWire: `systemctl --user status pipewire`. Check `wpctl status` for detected devices.
- **Build takes very long:** The CachyOS kernel compiles from source (~15-30 min). Everything else comes from binary cache. This is normal for the first build.

## Configuration Overview

| Module | Purpose |
|--------|---------|
| `flake.nix` | Entry point, inputs (nixpkgs-unstable, home-manager, nixos-hardware, cachyos-kernel) |
| `hosts/laptop/default.nix` | Bootloader (systemd-boot), CachyOS kernel, flakes, bluetooth, fwupd |
| `hosts/laptop/hardware.nix` | Disk layout (LUKS+Btrfs UUIDs), kernel modules, Intel microcode |
| `modules/gaming.nix` | Steam, Gamescope, Gamemode, MangoHud, Lutris, Heroic, ProtonUp-Qt, Xbox controllers |
| `modules/laptop/nvidia.nix` | NVIDIA open drivers, PRIME offload (Intel primary, RTX on demand via `nvidia-offload`) |
| `modules/laptop/power.nix` | zram (12GB, lz4), auto-cpufreq, thermald |
| `modules/laptop/rog.nix` | asusd (fan/LED/battery), supergfxd (GPU switching) |
| `modules/laptop/kernel-tweaks.nix` | Gaming sysctls, backlight params, split_lock_detect=off |
| `modules/laptop/btrfs-snapshots.nix` | Snapper: automatic hourly/daily/weekly snapshots for / and /home |
| `modules/desktop.nix` | KDE Plasma 6 + SDDM |
| `modules/audio.nix` | PipeWire + ALSA 32-bit |
| `modules/locale.nix` | Europe/Rome, en_US.UTF-8, Italian keyboard |
| `modules/networking.nix` | NetworkManager |
| `modules/packages.nix` | vim, wget, git, claude-code, firefox, pciutils, sensors, nvtop, htop |
| `modules/users.nix` | User marco (wheel, networkmanager, gamemode groups) |
| `home/common.nix` | Home Manager: git, starship prompt, btop |
