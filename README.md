# NixOS Configuration for ASUS ROG Zephyrus G16 (GU603VI-N4014W)

Gaming-optimized, modular NixOS flake configuration for the ASUS ROG Zephyrus G16, featuring LUKS encryption, Btrfs snapshots, CachyOS kernel, and NVIDIA hybrid graphics.

## Target Hardware

| Component | Specification |
|-----------|---------------|
| **Model** | ASUS ROG Zephyrus G16 GU603VI-N4014W |
| **CPU** | Intel Core i7-13620H (13th gen, 6P + 4E cores) |
| **GPU** | NVIDIA GeForce RTX 4070 Laptop (8GB) + Intel UHD (hybrid) |
| **RAM** | 48GB DDR4-3200 (16GB soldered + 32GB SO-DIMM) |
| **Storage** | 4TB PCIe 4.0 NVMe SSD |
| **Display** | 16" QHD+ 2560x1600 IPS 240Hz, DCI-P3 100%, G-Sync |
| **WiFi** | Wi-Fi 6E (802.11ax) tri-band + Bluetooth 5.3 |
| **Battery** | 90Wh 4-cell |

## Repository Structure

```
flake.nix                          # Entry point: inputs, host definitions
flake.lock                         # Pinned dependency versions
hosts/
  vm/
    default.nix                    # VM host config (aarch64, systemd-boot)
    hardware.nix                   # VM hardware (QEMU/UTM guest)
  laptop/
    default.nix                    # Laptop host config (Limine, CachyOS kernel)
    hardware.nix                   # Btrfs + LUKS partition template (EDIT THIS)
modules/
  locale.nix                       # Timezone (Europe/Rome), i18n, Italian keyboard
  desktop.nix                      # KDE Plasma 6 + SDDM
  audio.nix                        # PipeWire + ALSA + PulseAudio compat
  networking.nix                   # NetworkManager
  packages.nix                     # System-wide packages (vim, wget, git, firefox)
  users.nix                        # User account (marco)
  gaming.nix                       # Steam, Gamescope, Gamemode, MangoHud, controllers
  laptop/
    nvidia.nix                     # RTX 4070 proprietary + PRIME offload
    power.nix                      # zram, auto-cpufreq, thermald
    rog.nix                        # asusd, supergfxctl (fan profiles, GPU switching)
    kernel-tweaks.nix              # Gaming sysctls, split_lock_detect=off
    btrfs-snapshots.nix            # Snapper snapshot config
home/
  common.nix                       # Home Manager: git, starship, btop
```

## Flake Inputs

| Input | Source | Purpose |
|-------|--------|---------|
| `nixpkgs` | `nixos-unstable` | Base packages (latest) |
| `home-manager` | `nix-community/home-manager` | Declarative user environment |
| `nixos-hardware` | `NixOS/nixos-hardware` | Community hardware profiles |
| `nix-cachyos-kernel` | `xddxdd/nix-cachyos-kernel` (release) | Gaming-optimized kernel with BORE scheduler |

## Key Features

### Gaming Stack
- **Steam** with Proton, remote play, and local network transfer
- **Gamescope** micro-compositor with `capSysNice`
- **Gamemode** for dynamic CPU/GPU optimization during gameplay
- **MangoHud** FPS/stats overlay
- **Lutris** and **Heroic** for non-Steam games
- **ProtonUp-Qt** for managing Proton-GE versions
- **Xbox** (Bluetooth + wireless dongle) and **PS5** controller support

### NVIDIA Hybrid Graphics
- **Proprietary driver** (best performance for RTX 4070)
- **PRIME offload**: Intel iGPU for daily use, RTX 4070 on demand via `nvidia-offload`
- Fine-grained power management (GPU powers down when idle)
- 32-bit OpenGL support for Steam/Proton compatibility

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

### Snapper Snapshots
- Automatic timeline snapshots for `/` and `/home`
- Retention: 5 hourly, 7 daily, 4 weekly, 2 monthly
- Snapshot on every boot

### Power Management
- **zram** swap: lz4 compression, 25% of RAM (~12GB), no disk swap
- **auto-cpufreq**: powersave + no turbo on battery, performance + auto turbo on charger
- **thermald** for Intel thermal management

### ASUS ROG Features
- **asusd**: fan profiles, keyboard LED control, charge limit
- **supergfxctl**: GPU mode switching (hybrid / dedicated / integrated)

### Kernel Tweaks
- **CachyOS kernel** with BORE scheduler (gaming-optimized)
- `vm.max_map_count = 1048576` (required by many modern games)
- `vm.swappiness = 5` (prefer RAM with 48GB available)
- `split_lock_detect=off` (prevents game stuttering)
- **Limine** bootloader (10 generations max)

## Installation Guide

### Prerequisites

- NixOS installer USB (latest unstable ISO recommended)
- The ASUS ROG Zephyrus G16 GU603VI
- Internet connection

### Step 1: Boot the Installer

Boot from the NixOS USB. Open a terminal.

### Step 2: Partition the Drive

```bash
# Identify the NVMe drive
lsblk

# Create partitions: 4GB ESP + rest for LUKS
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 4GiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart primary 4GiB 100%

# Format the ESP
mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1
```

### Step 3: Set Up LUKS Encryption

```bash
# Encrypt the main partition
cryptsetup luksFormat --type luks2 /dev/nvme0n1p2

# Open it
cryptsetup open /dev/nvme0n1p2 cryptroot
```

### Step 4: Create Btrfs Subvolumes

```bash
# Format as Btrfs
mkfs.btrfs -L nixos /dev/mapper/cryptroot

# Mount and create subvolumes
mount /dev/mapper/cryptroot /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@var_log
umount /mnt

# Mount subvolumes with options
mount -o subvol=@,compress=zstd:1,noatime,ssd,discard=async /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{home,nix,.snapshots,var/log,boot}
mount -o subvol=@home,compress=zstd:1,noatime,ssd,discard=async /dev/mapper/cryptroot /mnt/home
mount -o subvol=@nix,compress=zstd:1,noatime,ssd,discard=async,nodev,nosuid /dev/mapper/cryptroot /mnt/nix
mount -o subvol=@snapshots,compress=zstd:1,noatime,ssd,discard=async /dev/mapper/cryptroot /mnt/.snapshots
mount -o subvol=@var_log,compress=zstd:1,noatime,ssd,discard=async /dev/mapper/cryptroot /mnt/var/log
mount /dev/nvme0n1p1 /mnt/boot
```

### Step 5: Generate Hardware Config

```bash
nixos-generate-config --root /mnt --show-hardware-config > /tmp/hardware.nix
```

Keep this output — you will need it in Step 7.

### Step 6: Clone This Repository

```bash
nix-shell -p git

# Clone into the NixOS config directory
git clone https://github.com/morettimarco/asus-gu603vi-n4014w.git /mnt/etc/nixos
```

### Step 7: Update Hardware Configuration

Edit `hosts/laptop/hardware.nix` with the real values:

```bash
# Get your partition UUIDs
blkid /dev/nvme0n1p2   # LUKS partition UUID
blkid /dev/nvme0n1p1   # ESP UUID
```

Replace in `hosts/laptop/hardware.nix`:
- `CHANGEME-LUKS-UUID` with the UUID of `/dev/nvme0n1p2` (the LUKS partition, NOT `/dev/mapper/cryptroot`)
- `CHANGEME-ESP-UUID` with the UUID of `/dev/nvme0n1p1`

Also merge any hardware-specific entries from the `nixos-generate-config` output (Step 5) that aren't already in the file, such as additional kernel modules.

### Step 8: Verify NVIDIA Bus IDs

```bash
lspci | grep VGA
```

You should see two entries (Intel and NVIDIA). Update the bus IDs in `modules/laptop/nvidia.nix` if they differ from:
- `intelBusId = "PCI:0:2:0"`
- `nvidiaBusId = "PCI:1:0:0"`

The format is `PCI:bus:device:function` — convert from lspci hex (e.g., `01:00.0` becomes `PCI:1:0:0`).

### Step 9: Install

```bash
nixos-install --flake /mnt/etc/nixos#laptop
```

Set the root password when prompted. After installation:

```bash
reboot
```

### Step 10: Post-Install

After booting into the new system:

```bash
# Set your user password
passwd marco

# Verify NVIDIA works
nvidia-smi
nvidia-offload glxinfo | grep "OpenGL renderer"

# Verify ASUS ROG tools
asusctl profile -l

# Test snapper
snapper -c root list
```

## VM Configuration

A VM configuration is included for development/testing on UTM (aarch64):

```bash
sudo nixos-rebuild switch --flake .#vm
```

This provides the same base stack (KDE Plasma 6, PipeWire, Home Manager) without laptop-specific hardware modules.

## Updating

```bash
# Update all flake inputs
nix flake update

# Rebuild
sudo nixos-rebuild switch --flake .#laptop
```

## Customization

### Adding Packages

System-wide packages go in `modules/packages.nix`. User packages go in `modules/users.nix` under `users.users.marco.packages`.

### Changing Desktop Environment

The desktop environment is configured in `modules/desktop.nix`. Currently set to KDE Plasma 6 with SDDM.

### GPU Modes

Switch between hybrid/dedicated/integrated GPU modes:

```bash
# Check current mode
supergfxctl -g

# Switch to dedicated GPU (best gaming performance)
supergfxctl -m Dedicated

# Switch back to hybrid (battery saving)
supergfxctl -m Hybrid
```

### Fan Profiles

```bash
# List profiles
asusctl profile -l

# Cycle to next profile
asusctl profile -n

# Set specific profile
asusctl profile -P Performance
```

### Btrfs Snapshot Rollback

```bash
# List snapshots
snapper -c root list

# Create manual snapshot
snapper -c root create -d "before risky change"

# Undo changes between snapshots
snapper -c root undochange 1..2
```

## License

This configuration is provided as-is for personal use.
