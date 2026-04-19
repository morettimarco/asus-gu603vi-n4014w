# NixOS Configuration for ASUS ROG Zephyrus G16 (GU603VI-N4014W)

Gaming-optimized, modular NixOS flake configuration for the ASUS ROG Zephyrus G16, featuring LUKS encryption, CachyOS kernel, NVIDIA hybrid graphics, and a full gaming stack.

## Target Hardware

| Component | Specification |
|-----------|---------------|
| **Model** | ASUS ROG Zephyrus G16 GU603VI-N4014W |
| **CPU** | Intel Core i7-13620H (13th gen, 6P + 4E cores, 16 threads) |
| **GPU** | NVIDIA GeForce RTX 4070 Max-Q (8GB) + Intel UHD (hybrid) |
| **RAM** | 48GB DDR4-3200 (16GB soldered + 32GB SO-DIMM) |
| **Storage** | Any drive with LUKS encryption + ext4 |
| **Display** | 16" QHD+ 2560x1600 IPS 240Hz, G-Sync |
| **WiFi** | Intel AX211 Wi-Fi 6E + Bluetooth 5.3 |

## What You Get

- **KDE Plasma 6** desktop with SDDM login manager
- **CachyOS kernel** with BORE scheduler (gaming-optimized)
- **NVIDIA hybrid graphics** — Intel iGPU for daily use, RTX 4070 on demand
- **Full gaming stack** — Steam (Proton-GE), Lutris, Heroic, MangoHud, Gamescope, Gamemode
- **Xbox controller support** — Bluetooth (xpadneo) and wireless dongle (xone)
- **ASUS ROG controls** — fan profiles, keyboard LEDs, GPU switching, battery charge limit
- **Power management** — zram swap, auto-cpufreq, thermald
- **PipeWire audio** with ALSA 32-bit support (for Steam/Proton)
- **Home Manager** — declarative user environment (git, shell prompt, btop)

## Prerequisites

This guide assumes you have:

1. The ASUS ROG Zephyrus G16 GU603VI (or similar hardware)
2. A fresh NixOS installation with **KDE Plasma 6 desktop** (installed via the NixOS graphical installer, with LUKS encryption and ext4)
3. A working internet connection

The NixOS graphical installer handles partitioning, LUKS encryption, and the base install for you. This configuration is then applied **on top** of that fresh install.

## Installation

There are two ways to set up this configuration: manually step by step, or automatically using Claude Code. Both start from a freshly installed NixOS system.

### Option A: Manual Installation

#### Step 1: Enable Flakes

Flakes are the modern way to manage NixOS configurations but aren't enabled by default. Edit the system config that the installer created:

```bash
sudo vim /etc/nixos/configuration.nix
```

Add this line anywhere inside the curly braces:

```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

Apply the change:

```bash
sudo nixos-rebuild switch
```

#### Step 2: Clone This Repository

```bash
git clone https://github.com/morettimarco/asus-gu603vi-n4014w.git ~/nixos-config
cd ~/nixos-config
```

#### Step 3: Configure hardware.nix

The file `hosts/laptop/hardware.nix` contains `CHANGEME` placeholders that must be replaced with your actual disk UUIDs.

**If the NixOS installer set up LUKS encryption** (the default when you check "Encrypt" during install):

Find your UUIDs:

```bash
# Your LUKS partition UUID (the encrypted partition, NOT the mapper)
sudo blkid | grep crypto_LUKS
# Your ESP (boot) partition UUID
sudo blkid | grep -i fat
```

Edit `hosts/laptop/hardware.nix` and replace:
- Every instance of `CHANGEME-LUKS-UUID` with your LUKS partition's UUID
- `CHANGEME-ESP-UUID` with your ESP partition's UUID

**If the NixOS installer did NOT set up LUKS** (plain ext4 without encryption):

Replace `hardware.nix` entirely with your actual hardware config:

```bash
nixos-generate-config --show-hardware-config > ~/nixos-config/hosts/laptop/hardware.nix
```

#### Step 4: Verify GPU Bus IDs

Check that the GPU PCI addresses match your hardware:

```bash
lspci | grep VGA
```

Expected output:
```
00:02.0 VGA compatible controller: Intel Corporation ...
01:00.0 VGA compatible controller: NVIDIA Corporation ...
```

If the addresses are different, edit `modules/laptop/nvidia.nix` and update `intelBusId` and `nvidiaBusId`. The format is `PCI:bus:device:function` in decimal (e.g., `01:00.0` becomes `PCI:1:0:0`).

#### Step 5: Customize User Settings

The default username is `marco`. If you want a different username, update it in:
- `modules/users.nix` — the user account
- `home/common.nix` — the Home Manager `username` and `homeDirectory`
- `home/common.nix` — git `user.name` and `user.email`

#### Step 6: Build and Apply

Use `boot` for the first apply — it's safer than `switch` because it only activates on reboot, so if anything goes wrong you can still select the previous generation from the boot menu:

```bash
cd ~/nixos-config
sudo nixos-rebuild boot --flake .#zephyrus
```

If the build succeeds, reboot:

```bash
sudo reboot
```

#### Step 7: Verify

After rebooting, check that everything is working:

```bash
uname -r                    # Should show a cachyos kernel version
nvidia-smi                  # Should show RTX 4070 and driver version
asusctl profile -l          # Should list Quiet/Balanced/Performance
zramctl                     # Should show ~12GB lz4 swap
steam                       # Should launch Steam
```

### Option B: Using Claude Code

If you have Claude Code available (or can install it), it can handle the entire setup automatically:

```bash
# If claude-code isn't installed yet, get it temporarily:
nix shell nixpkgs#claude-code

# Then run:
claude
```

Once in the Claude Code prompt, say:

```
Set up my system using https://github.com/morettimarco/asus-gu603vi-n4014w
```

Claude Code will read the `CLAUDE.md` file in this repo, which contains detailed autonomous setup instructions. It will:

1. Clone the repository
2. Detect your disk layout and UUIDs
3. Configure `hardware.nix` for your system
4. Verify GPU bus IDs
5. Build and apply the configuration
6. Guide you through a reboot and verification

## Repository Structure

```
flake.nix                              # Entry point: inputs, host definitions
flake.lock                             # Pinned dependency versions
CLAUDE.md                              # Autonomous setup instructions for Claude Code
hosts/
  laptop/
    default.nix                        # Bootloader (systemd-boot), CachyOS kernel
    hardware.nix                       # Disk layout — EDIT with your UUIDs
modules/
  locale.nix                           # Timezone (Europe/Rome), i18n, Italian keyboard
  desktop.nix                          # KDE Plasma 6 + SDDM
  audio.nix                            # PipeWire + ALSA 32-bit
  networking.nix                       # NetworkManager
  packages.nix                         # System packages (vim, git, firefox, htop, etc.)
  users.nix                            # User account
  gaming.nix                           # Steam, Gamescope, Gamemode, MangoHud, controllers
  laptop/
    nvidia.nix                         # RTX 4070 open drivers + PRIME offload
    power.nix                          # zram, auto-cpufreq, thermald
    rog.nix                            # asusd, supergfxctl (fan profiles, GPU switching)
    kernel-tweaks.nix                  # Gaming sysctls, backlight, split_lock_detect=off
home/
  common.nix                           # Home Manager: git, starship prompt, btop
```

## Daily Usage

### Updating the System

```bash
cd ~/nixos-config
nix flake update                              # Fetch latest package versions
sudo nixos-rebuild switch --flake .#zephyrus   # Apply updates
```

After updating, commit the lock file to preserve the exact state:

```bash
git add flake.lock
git commit -m "Update flake inputs"
```

### Installing New Packages

Edit `modules/packages.nix` and add the package name to the list, then rebuild. Search for packages at https://search.nixos.org/packages or with `nix search nixpkgs <name>`.

### GPU Modes

```bash
# Run a game or app on the NVIDIA GPU
nvidia-offload <command>

# Steam launch option for NVIDIA
nvidia-offload %command%

# Switch GPU mode (requires logout)
supergfxctl -g                    # Current mode
supergfxctl -m Hybrid             # Intel + NVIDIA on demand (default)
supergfxctl -m Integrated         # Intel only (max battery)
```

### ASUS ROG Controls

```bash
asusctl profile -l                # List power profiles
asusctl profile -P Quiet          # Set quiet mode
asusctl profile -P Performance    # Set performance mode
asusctl -c 80                     # Limit battery charge to 80%
```

### Rolling Back

If a rebuild breaks something, reboot and select a previous generation from the systemd-boot menu. Or from the command line:

```bash
sudo nixos-rebuild switch --rollback
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| **Emergency console after rebuild** | Reboot, pick previous generation. Check that `hardware.nix` UUIDs match your actual disk (`sudo blkid`) |
| **NVIDIA driver fails after reboot** | Boot previous generation. Check `modules/laptop/nvidia.nix` bus IDs match `lspci \| grep VGA` |
| **CachyOS kernel won't build** | Temporarily use `boot.kernelPackages = pkgs.linuxPackages_latest;` in `hosts/laptop/default.nix` and remove the CachyOS overlay |
| **No audio** | Check PipeWire: `systemctl --user status pipewire` and `wpctl status` |
| **Screen brightness broken** | Check `ls /sys/class/backlight/` — the config uses `i915.enable_dpcd_backlight=1` |
| **Build takes 15-30 minutes** | Normal for first build — the CachyOS kernel compiles from source. Subsequent rebuilds are fast |

## License

This configuration is provided as-is for personal use.
