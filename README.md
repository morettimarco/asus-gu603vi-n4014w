# NixOS Configuration for ASUS ROG Zephyrus G16 (GU603VI-N4014W)

Gaming-optimized, modular NixOS flake configuration for the ASUS ROG Zephyrus G16, featuring LUKS encryption, CachyOS kernel, NVIDIA hybrid graphics, and a full gaming stack.

> [!WARNING]
> **If you installed this config before November 2026, pull and rebuild.** Earlier versions trust the CachyOS kernel binary cache at `attic.xuyh0120.win` and its signing key. Those servers were compromised and the key may have been stolen ([nix-cachyos-kernel#110](https://github.com/xddxdd/nix-cachyos-kernel/issues/110)). Nix accepts anything signed with a trusted key, so your machine keeps trusting the old key until you rebuild with the current config.

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
- **ASUS ROG controls** — fan profiles, keyboard LEDs (restored after sleep), GPU switching, battery charge limit, M4 key cycles LED modes
- **Power management** — zram swap, auto-cpufreq, thermald
- **Thunderbolt 4** — device authorization with `boltctl`
- **Encrypted boot polish** — Plymouth splash with a graphical LUKS prompt, silent boot
- **Self-maintaining storage** — SSD TRIM through LUKS, and weekly cleanup that deletes generations older than 14 days
- **PipeWire audio** with ALSA 32-bit support (for Steam/Proton)
- **Home Manager** — declarative user environment (git, shell prompt, btop)
- **Optional face login** — Howdy with the IR camera, off by default (see [Face Login](#face-login-optional))

## Prerequisites

This guide assumes you have:

1. The ASUS ROG Zephyrus G16 GU603VI (or similar hardware)
2. A fresh NixOS installation with **KDE Plasma 6 desktop** (installed via the NixOS graphical installer, with LUKS encryption and ext4)
3. A working internet connection

The NixOS graphical installer handles partitioning, LUKS encryption, and the base install for you. This configuration is then applied **on top** of that fresh install.

## Installation

There are two ways to set up this configuration: manually step by step, or automatically using Claude Code. Both start from a freshly installed NixOS system.

### Option A: Manual Installation

#### Step 1: Install Prerequisites and Enable Flakes

A fresh NixOS install doesn't include `git`, `vim`, `lspci`, or other common tools. Start by adding them and enabling flakes. Use `nano` (the only editor available by default) to edit the system config:

```bash
sudo nano /etc/nixos/configuration.nix
```

Add these lines anywhere inside the curly braces:

```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
environment.systemPackages = with pkgs; [ git vim pciutils ];
```

Save (`Ctrl+O`, `Enter`) and exit (`Ctrl+X`), then apply the change:

```bash
sudo nixos-rebuild switch
```

#### Step 2: Clone This Repository

```bash
git clone https://github.com/morettimarco/asus-gu603vi-n4014w.git ~/nixos-config
cd ~/nixos-config
```

#### Step 3: Configure hardware.nix

The file `hosts/laptop/hardware.nix` contains `CHANGEME` placeholders that must be replaced with your actual disk UUIDs and layout. The simplest approach is to replace the entire file with your system's auto-detected hardware config:

```bash
nixos-generate-config --show-hardware-config > ~/nixos-config/hosts/laptop/hardware.nix
```

This generates a complete hardware configuration with the correct UUIDs, kernel modules, and filesystem layout for your machine — whether you used LUKS encryption or not.

**Verify the result:**

```bash
cat ~/nixos-config/hosts/laptop/hardware.nix
```

Check that it contains:
- A `fileSystems."/"` entry (your root partition)
- A `fileSystems."/boot"` entry (your ESP/boot partition)
- If you enabled LUKS encryption during install, a `boot.initrd.luks.devices` entry

**Restore the SSD options.** The generated file doesn't include them, so add `options = [ "noatime" ];` to `fileSystems."/"` and `allowDiscards = true;` to your `boot.initrd.luks.devices` entry. Without `allowDiscards`, TRIM can't reach the SSD through LUKS.

<details>
<summary>Alternative: editing hardware.nix manually</summary>

If you prefer to edit the existing template rather than replacing it, you need your disk UUIDs. List all block devices:

```bash
sudo blkid
```

This outputs something like:

```
/dev/nvme0n1p1: UUID="ABCD-1234" TYPE="vfat" PARTLABEL="EFI System Partition" ...
/dev/nvme0n1p2: UUID="12345678-abcd-..." TYPE="crypto_LUKS" PARTLABEL="root" ...
/dev/mapper/luks-...: UUID="87654321-dcba-..." TYPE="ext4" ...
```

Identify your partitions by their `TYPE`:
- **`TYPE="vfat"`** with `PARTLABEL="EFI System Partition"` — this is your **ESP UUID** (replace `CHANGEME-ESP-UUID`)
- **`TYPE="crypto_LUKS"`** — this is your **LUKS UUID** (replace all 3 instances of `CHANGEME-LUKS-UUID`)
- If you don't have LUKS, the **root UUID** is the `TYPE="ext4"` entry on your main partition

Edit `hosts/laptop/hardware.nix` and replace the placeholders with the matching UUIDs.

</details>

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

#### Step 5: Set Your Username and Personal Details

The configuration uses `CHANGEME` placeholders for the username and personal details. You **must** replace them before building. Search for `CHANGEME` across the repo to find all of them, or update these specific files:

**`modules/users.nix`** — your Linux user account:
- `CHANGEME_USERNAME` → your Linux username (e.g., `alice`)
- `CHANGEME_DESCRIPTION` → your display name (e.g., `Alice`)

**`home/common.nix`** — Home Manager and git identity:
- `CHANGEME_USERNAME` → same Linux username as above
- `/home/CHANGEME_USERNAME` → your home directory path
- `CHANGEME_FULL_NAME` → your full name for git commits
- `CHANGEME_EMAIL` → your email for git commits

**`flake.nix`** — Home Manager user mapping:
- `users.CHANGEME_USERNAME` → same Linux username as above

#### Step 6: Build and Apply

Use `boot` for the first apply — it's safer than `switch` because it only activates on reboot, so if anything goes wrong you can still select the previous generation from the boot menu:

```bash
cd ~/nixos-config
sudo nixos-rebuild boot --flake .#zephyrus \
  --option extra-substituters https://cache.lantian.pub/lantian \
  --option extra-trusted-public-keys lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ=
```

The two `--option` flags are only needed this once. Your system doesn't trust the kernel binary cache until this config is applied, so without them the CachyOS kernel compiles from source, which can take over 30 minutes.

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
systemctl is-active tlp auto-cpufreq   # tlp inactive, auto-cpufreq active
boltctl list                # Should run without errors
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
workarounds.json                       # Temporary fixes, with checks for when they can go
hosts/
  laptop/
    default.nix                        # Bootloader, CachyOS kernel, Plymouth, store cleanup, TRIM
    hardware.nix                       # Disk layout — EDIT with your UUIDs
modules/
  locale.nix                           # Timezone (Europe/Rome), i18n, Italian keyboard
  desktop.nix                          # KDE Plasma 6 + SDDM
  audio.nix                            # PipeWire + ALSA 32-bit
  networking.nix                       # NetworkManager
  packages.nix                         # System packages (vim, git, firefox, htop, etc.)
  users.nix                            # User account
  gaming.nix                           # Steam, Gamescope, Gamemode, MangoHud, controllers, uinput, ntsync
  laptop/
    nvidia.nix                         # RTX 4070 open drivers + PRIME offload
    power.nix                          # zram, auto-cpufreq, thermald; TLP off
    rog.nix                            # asusd, supergfxctl, keyboard LEDs after resume, lid/power wake
    thunderbolt.nix                    # bolt daemon, boltctl
    m4-aura.nix                        # M4 key cycles keyboard LED modes
    howdy.nix                          # Optional face login (not imported by default)
    kernel-tweaks.nix                  # Gaming sysctls, writeback limits, backlight, silent boot
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

The M4 key cycles keyboard LED modes. If you change its binding later, apply it with `sudo systemctl restart 'actkbd@*'` or a reboot, because running instances keep the old config across a rebuild.

### Thunderbolt Devices

New devices stay unauthorized until you trust them:

```bash
boltctl list
boltctl enroll <uuid>
```

### Face Login (Optional)

Howdy lets you authenticate with the IR camera. It's off by default because it changes how `sudo` and other logins work.

1. Uncomment `./modules/laptop/howdy.nix` in `flake.nix`.
2. Check `device_path` in `modules/laptop/howdy.nix` against `ls /dev/v4l/by-path/`.
3. Rebuild, then enrol your face with `sudo howdy add`.
4. Test with `sudo -k && sudo echo ok`.

The module uses `control = "sufficient"`, so a recognized face is enough on its own, and **a printed photo can fool it**. Set `control = "required"` to need both your face and your password.

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
| **First build compiles the kernel** | The binary cache isn't trusted until this config is applied. Use the `--option` flags in [Step 6](#step-6-build-and-apply). Later rebuilds fetch it |
| **Steam still opens a "Remote Control" prompt** | Log out and back in so the new `uinput` and `input` groups apply, then check with `id` |
| **Keyboard dark after sleep** | Check `journalctl -u sleep-actions -b \| grep aura-reapply`. Brightness 0 is left alone on purpose: KDE dims the keyboard while idle and restores it on input |

## Known Issues

These are upstream problems this config works around. Each has an entry in `workarounds.json` with a check that tells you when it can be removed.

- **`asus-shutdown` and rebuilds.** The service refuses to stop until real shutdown, which would make `nixos-rebuild switch` fail, so rebuilds leave it running. If you see a stuck instance from an older config, kill its PID with `sudo kill -9 <pid>`, then run `sudo systemctl reset-failed asus-shutdown.service` and `sudo systemctl start asus-shutdown.service`.
- **Keyboard LEDs after sleep.** asusd doesn't restore them on wake, so `modules/laptop/rog.nix` re-sends the LED mode and brightness.
- **Lid and power button wake.** The firmware doesn't mark the lid's event line as a wake source, so on Linux only the keyboard or other USB input could wake the laptop from sleep. `modules/laptop/rog.nix` adds the missing definition as a small ACPI table in early boot, without changing the firmware. Tested on BIOS GU603VI.317; check with `grep LID0 /proc/acpi/wakeup`, which should show it enabled. Side effect: unplugging the charger also wakes the laptop. Don't switch to `deep` sleep instead: on that BIOS it didn't resume at all.
- **Howdy and polkit.** polkit's sandbox blocks the IR camera, which also breaks password fallback in admin prompts. `modules/laptop/howdy.nix` opens the sandbox to the camera.

Things to watch for when changing this config:

- **Don't add `inputs.nixpkgs.follows` to `nix-cachyos-kernel`.** The kernel would no longer match the binary cache, and every update would compile it locally.
- **TLP must stay off.** The nixos-hardware profile enables it whenever `power-profiles-daemon` is off, and it conflicts with auto-cpufreq.
- **Flake updates can add apps.** A changed default in nixpkgs can install new programs with no change here, which is why KDE PIM is explicitly disabled.
- **New groups need a fresh login.** Changes to `extraGroups` don't reach your running session.
- **Use `boot` when touching the kernel, LUKS or NVIDIA settings.** If it goes wrong, you can pick the previous generation at the boot menu.
- **NVMe names can swap between boots.** Identify disks by model with `lsblk -o NAME,MODEL,SIZE` before any destructive command.

## License

This configuration is provided as-is for personal use.
