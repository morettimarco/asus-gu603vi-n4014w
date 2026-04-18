# NixOS Configuration for ASUS ROG Zephyrus G16 (GU603VI-N4014W)

Gaming-optimized, modular NixOS flake configuration for the ASUS ROG Zephyrus G16, featuring LUKS encryption, Btrfs snapshots, CachyOS kernel, and NVIDIA hybrid graphics.

**Verified working** on actual hardware (2026-04-17).

## Target Hardware

| Component | Specification |
|-----------|---------------|
| **Model** | ASUS ROG Zephyrus G16 GU603VI-N4014W |
| **CPU** | Intel Core i7-13620H (13th gen, 6P + 4E cores, 16 threads) |
| **GPU** | NVIDIA GeForce RTX 4070 Max-Q (8GB, AD106M) + Intel UHD (hybrid) |
| **RAM** | 48GB DDR4-3200 (16GB soldered + 32GB SO-DIMM) |
| **Storage** | 4TB PCIe 4.0 NVMe SSD |
| **Display** | 16" QHD+ 2560x1600 IPS 240Hz, DCI-P3 100%, G-Sync |
| **WiFi** | Intel AX211 Wi-Fi 6E tri-band + Bluetooth 5.3 |
| **Battery** | 90Wh 4-cell |

## Quick Start

On a fresh NixOS install (any filesystem, any drive):

```bash
# 1. Enable flakes (add to /etc/nixos/configuration.nix):
#    nix.settings.experimental-features = [ "nix-command" "flakes" ];
#    then: sudo nixos-rebuild switch

# 2. Clone the repo
nix-shell -p git --run "git clone https://github.com/morettimarco/asus-gu603vi-n4014w.git ~/nixos-config"

# 3. Replace hardware.nix with your actual hardware
nixos-generate-config --show-hardware-config > ~/nixos-config/hosts/laptop/hardware.nix

# 4. Build and apply
cd ~/nixos-config
sudo nixos-rebuild boot --flake .#zephyrus

# 5. Reboot
sudo reboot
```

### With Claude Code

Alternatively, install `claude-code` and let it handle everything autonomously:

```bash
claude
> Set up my system using https://github.com/morettimarco/asus-gu603vi-n4014w
```

The `CLAUDE.md` file contains full autonomous setup instructions.

## Repository Structure

```
CLAUDE.md                              # Autonomous setup instructions for Claude Code
flake.nix                              # Entry point: inputs, host definitions
flake.lock                             # Pinned dependency versions
hosts/
  laptop/
    default.nix                        # Bootloader (systemd-boot), CachyOS kernel
    hardware.nix                       # LUKS + Btrfs partition template (EDIT UUIDs)
modules/
  locale.nix                           # Timezone (Europe/Rome), i18n, Italian keyboard
  desktop.nix                          # KDE Plasma 6 + SDDM
  audio.nix                            # PipeWire + ALSA + PulseAudio compat
  networking.nix                       # NetworkManager
  packages.nix                         # System packages (vim, git, firefox, sensors, nvtop)
  users.nix                            # User account (marco)
  gaming.nix                           # Steam, Gamescope, Gamemode, MangoHud, controllers
  laptop/
    nvidia.nix                         # RTX 4070 open driver + PRIME offload
    power.nix                          # zram, auto-cpufreq, thermald
    rog.nix                            # asusd, supergfxctl (fan profiles, GPU switching)
    kernel-tweaks.nix                  # Gaming sysctls, backlight, split_lock_detect=off
    btrfs-snapshots.nix                # Snapper snapshot config
home/
  common.nix                           # Home Manager: git, starship, btop
```

## Flake Inputs

| Input | Source | Purpose |
|-------|--------|---------|
| `nixpkgs` | `nixos-unstable` | Base packages (latest) |
| `home-manager` | `nix-community/home-manager` | Declarative user environment |
| `nixos-hardware` | `NixOS/nixos-hardware` | ASUS Zephyrus hardware profile (`gu603h`) |
| `nix-cachyos-kernel` | `xddxdd/nix-cachyos-kernel` (release) | Gaming-optimized kernel with BORE scheduler |

## Key Features

### Gaming Stack
- **Steam** with Proton, remote play, and local network transfer
- **Gamescope** micro-compositor with `capSysNice`
- **Gamemode** for dynamic CPU/GPU optimization during gameplay
- **MangoHud** FPS/stats overlay
- **Lutris** and **Heroic** for non-Steam games
- **ProtonUp-Qt** for managing Proton-GE versions
- **Xbox** (Bluetooth via xpadneo + wireless dongle via xone) controller support

### NVIDIA Hybrid Graphics
- **Open kernel modules** (recommended by NVIDIA for Ada Lovelace GPUs)
- **PRIME offload**: Intel iGPU for daily use, RTX 4070 on demand via `nvidia-offload`
- Fine-grained power management (GPU powers down when idle)
- 32-bit OpenGL support for Steam/Proton compatibility
- Backlight handled by Intel i915 (NVIDIA handler disabled to prevent conflicts)

### Storage: LUKS + Btrfs
- Full disk encryption with LUKS2
- NVMe optimizations: `allowDiscards`, `bypassWorkqueues`
- Btrfs with zstd compression and five subvolumes:

| Subvolume | Mount | Purpose |
|-----------|-------|---------|
| `@` | `/` | Root filesystem |
| `@home` | `/home` | User data |
| `@nix` | `/nix` | Nix store (nodev, nosuid) |
| `@snapshots` | `/.snapshots` | Snapper snapshots |
| `@var_log` | `/var/log` | System logs |

### Automatic Snapshots
- Snapper timeline snapshots for `/` and `/home`
- Retention: 5 hourly, 7 daily, 4 weekly, 2 monthly
- Snapshot on every boot

### Power Management
- **zram** swap: lz4 compression, 25% of RAM (~12GB), no disk swap
- **auto-cpufreq**: powersave + no turbo on battery, performance + auto turbo on charger
- **thermald** for Intel thermal management

### ASUS ROG Features
- **asusd**: fan profiles (Quiet/Balanced/Performance), keyboard LED control, charge limit
- **supergfxctl**: GPU mode switching (Integrated / Hybrid / AsusMuxDgpu)

### Kernel Tweaks
- **CachyOS kernel** with BORE scheduler (gaming-optimized)
- `vm.max_map_count = 1048576` (required by many modern games)
- `vm.swappiness = 5` (prefer RAM with 48GB available)
- `split_lock_detect=off` (prevents game stuttering)
- Backlight: `i915.enable_dpcd_backlight=1` with NVIDIA handler disabled

## Manual Installation Guide

### Prerequisites

- NixOS installer USB (latest unstable ISO recommended)
- The ASUS ROG Zephyrus G16 GU603VI
- Internet connection

### Step 1: Boot the Installer and Partition

```bash
# Create partitions: 4GB ESP + rest for LUKS
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 4GiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart primary 4GiB 100%

# Format ESP
mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1

# Set up LUKS encryption
cryptsetup luksFormat --type luks2 /dev/nvme0n1p2
cryptsetup open /dev/nvme0n1p2 cryptroot

# Create Btrfs with subvolumes
mkfs.btrfs -L nixos /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@var_log
umount /mnt

# Mount everything
mount -o subvol=@,compress=zstd:1,noatime,ssd,discard=async /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{home,nix,.snapshots,var/log,boot}
mount -o subvol=@home,compress=zstd:1,noatime,ssd,discard=async /dev/mapper/cryptroot /mnt/home
mount -o subvol=@nix,compress=zstd:1,noatime,ssd,discard=async,nodev,nosuid /dev/mapper/cryptroot /mnt/nix
mount -o subvol=@snapshots,compress=zstd:1,noatime,ssd,discard=async /dev/mapper/cryptroot /mnt/.snapshots
mount -o subvol=@var_log,compress=zstd:1,noatime,ssd,discard=async /dev/mapper/cryptroot /mnt/var/log
mount /dev/nvme0n1p1 /mnt/boot
```

### Step 2: Install Minimal NixOS

```bash
nixos-generate-config --root /mnt
# Edit /mnt/etc/nixos/configuration.nix to add:
#   nix.settings.experimental-features = [ "nix-command" "flakes" ];
#   environment.systemPackages = [ pkgs.git pkgs.vim ];
#   users.users.marco = { isNormalUser = true; extraGroups = [ "wheel" ]; };
nixos-install
reboot
```

### Step 3: Clone and Apply This Config

After booting into the minimal install:

```bash
git clone https://github.com/morettimarco/asus-gu603vi-n4014w.git ~/nixos-config
cd ~/nixos-config

# Get your UUIDs
blkid /dev/nvme0n1p2 -s UUID -o value  # LUKS UUID
blkid /dev/nvme0n1p1 -s UUID -o value  # ESP UUID

# Edit hosts/laptop/hardware.nix — replace CHANGEME values with real UUIDs
vim hosts/laptop/hardware.nix

# Build and apply
sudo nixos-rebuild switch --flake .#zephyrus

# Reboot to load CachyOS kernel + NVIDIA drivers
sudo reboot
```

### Step 4: Verify

```bash
uname -r              # CachyOS kernel
nvidia-smi            # RTX 4070 detected
asusctl profile list  # Quiet/Balanced/Performance
zramctl               # ~12GB lz4 swap
steam                 # Launch Steam
```

## Daily Usage

### GPU Modes

```bash
# Run a game on the NVIDIA GPU
nvidia-offload <game-command>

# In Steam: set launch options to
nvidia-offload %command%

# Switch GPU mode (requires logout)
supergfxctl -s                    # Show available modes
supergfxctl -m Hybrid             # Hybrid (battery saving)
supergfxctl -m AsusMuxDgpu        # Dedicated (max performance)
```

### ASUS Controls

```bash
asusctl profile list              # List power profiles
asusctl profile get               # Current profile
asusctl profile set Performance   # Set profile
asusctl leds brightness <0-3>     # Keyboard backlight
asusctl battery limit 80          # Charge limit (extends battery life)
```

### Snapshots

```bash
snapper -c root list                          # List root snapshots
snapper -c home list                          # List home snapshots
snapper -c root create -d "before upgrade"    # Manual snapshot
snapper -c root undochange 1..2               # Undo changes
```

### Updating

```bash
cd ~/nixos-config
nix flake update                              # Update all inputs
sudo nixos-rebuild switch --flake .#zephyrus    # Apply
```

## License

This configuration is provided as-is for personal use.
