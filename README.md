# VoltageOS for Nothing Phone (1) (Spacewar)

Local manifest for building VoltageOS on the Nothing Phone (1).

## Included Projects

| Path | Repository | Branch |
|------|------------|--------|
| `device/nothing/Spacewar` | [ang3lo-azevedo/android_device_nothing_Spacewar](https://github.com/ang3lo-azevedo/android_device_nothing_Spacewar) | `voltage` |
| `kernel/nothing/sm7325` | [ang3lo-azevedo/android_kernel_nothing_sm7325](https://github.com/ang3lo-azevedo/android_kernel_nothing_sm7325) | `voltage-nethunter` |
| `vendor/nothing/Spacewar` | [DaViDev985/vendor_nothing_Spacewar](https://github.com/DaViDev985/vendor_nothing_Spacewar) | `derp16.2` |
| `vendor/nothing/camera` | [DaViDev985/proprietary_vendor_nothing_camera](https://github.com/DaViDev985/proprietary_vendor_nothing_camera) | `derp16` |
| `hardware/nothing` | [ang3lo-azevedo/android_hardware_nothing](https://github.com/ang3lo-azevedo/android_hardware_nothing) | `16.2-nglyphs` |
| `hardware/dolby` | [kleidione/hardware_dolby](https://github.com/kleidione/hardware_dolby) | `bp4a` |
| `vendor/google/GoogleCamera` | [kleidione/vendor_google_GoogleCamera](https://github.com/kleidione/vendor_google_GoogleCamera) | `bp3a` |
| `vendor/voltage-priv/keys` | [ang3lo-azevedo/vendor_voltage-priv_keys](https://github.com/ang3lo-azevedo/vendor_voltage-priv_keys) | `main` |

### Tree Sources

The device tree (`android_device_nothing_Spacewar`) merges improvements from:

- **kleidione/bp4a** - base with NOS 3.2 fixes (vibrator, FP, power profile, ghost touch fix)
- **DaViDev985/derp16.2** - NOS 3.2 post_boot.sh, sepolicy perf, FP screen-off unlock, camera sepolicy
- **smrth097/luna** - perf init script, IRQ balance config, SPAMMY_LOG_TAGS, QTI vndfwk
- **crDroid/derp16** - NOS 3.2 EOL mixer paths, camcorder audio, radio power saving, Bluetooth ASHA/AptX, sensor calibration libs
- **halogenOS/XOS-16.2** - linear-nits brightness mapping, Extra Dim evening dimmer
- **StudioKeys-Dumps/waterlily-qpr2** - NGlyphs/GlyphManager, recovery ADSP

The hardware/nothing tree (`android_hardware_nothing`) is based on:

- **DaViDev985/derp16.2** - base with NtOnlineConfig stub (required for Nothing Camera)
- **StudioKeys-Dumps/waterlily-qpr2** - NGlyphs/GlyphManager (20 commits, replaces ParanoidGlyph)
- **kleidione/bp4a** - FP goodix_fp node wait and HAL null guards

The vendor and camera blobs come from DaViDev985 (NOS 3.2, photo/video working, portrait on Google Camera).

The kernel (`android_kernel_nothing_sm7325`) is based on:

- **William24hmar/KSU-SUSFS** - KSU syscall tamper, full SUSFS
- **William24hmar/Nethunter** - NetHunter configs (monitor mode, WireGuard, HID gamepads)
- **maxsteeel/nomount** - NoMount path redirection subsystem
- **rodrig20/moonwake** - USB gadget reconfiguration, HID keyboard descriptor

## Prerequisites

- Android `repo` tool installed
- Git configured with GitHub authentication
- At least 200GB free disk space

## GitHub Authentication

This manifest includes private repositories. Set up authentication first.

### Option A: GitHub CLI

```bash
gh auth login --hostname github.com --git-protocol https
gh auth setup-git
```

Verify: `git ls-remote https://github.com/ang3lo-azevedo/vendor_voltage-priv_keys.git`

### Option B: Manual PAT

1. Create a token at https://github.com/settings/tokens with `repo` scope
2. Store credentials:

```bash
git config --global credential.helper store
read -p "GitHub username: " GH_USER
read -s -p "GitHub PAT: " GH_PAT; echo
printf "protocol=https\nhost=github.com\nusername=%s\npassword=%s\n\n" "$GH_USER" "$GH_PAT" | git credential approve
```

## Usage

### 1. Initialize the repo

```bash
repo init -u https://github.com/VoltageOS/manifest.git -b <branch>
```

### 2. Add the local manifest

Clone this repository into `.repo/local_manifests/`:

```bash
git clone https://github.com/ang3lo-azevedo/local_manifests.git .repo/local_manifests
```

### 3. Sync

```bash
repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune
```

### 4. Build

```bash
source build/envsetup.sh
breakfast Spacewar
brunch Spacewar
```

Or with `mka`:

```bash
mka bacon
```

## Build Configuration

```
VOLTAGE_VERSION=5.8-Spacewar-YYYYMMDD-HHMM-UNOFFICIAL
BUILD_ID=BP4A.251205.006
TARGET_PRODUCT=voltage_Spacewar
TARGET_BUILD_VARIANT=user
```

Output goes to `out/target/product/Spacewar/`.

## Troubleshooting

### "Cannot locate config makefile"

Repos did not sync properly. Rerun:

```bash
repo sync -c -j$(nproc) --force-sync
```

### "Cannot fetch repository"

Check GitHub authentication with:

```bash
git ls-remote https://github.com/ang3lo-azevedo/vendor_voltage-priv_keys.git
```

### Missing proprietary files

Some prebuilt binaries may be missing from the vendor tree. Verify the branch exists and has the required files. Comment out missing modules from `Android.bp` if necessary.

### Duplicate sysprop assignments (audio)

If the build fails with `found duplicate sysprop assignments` for `ro.config.ringtone`, `ro.config.notification_sound`, or `ro.config.alarm_alert`, the ROM and device tree are both setting these properties on the product partition. Fix by using weak assignment in the ROM config:

```bash
sed -i 's/ro.config.ringtone=/ro.config.ringtone?=/; s/ro.config.alarm_alert=/ro.config.alarm_alert?=/; s/ro.config.notification_sound=/ro.config.notification_sound?=/' vendor/voltage/audio/audio.mk
```

This allows the device tree to override the ROM defaults with Nothing tones without a build conflict.

### ServerHive Build Server

If building on [ServerHive](https://github.com/ServerHive-Development/guide) bare-metal servers:

**SSH access:**

```bash
ssh username@server.serverhive.com -p 22
```

**Persistent sessions (Byobu):**

ServerHive uses Byobu as the default terminal multiplexer. Your build keeps running even if you disconnect.

```bash
# Detach: F6 or Ctrl+A then D
# New window: F2
# Navigate windows: F3 (previous) / F4 (next)
# Reattach after disconnect: byobu
```

**Git cookies (avoid rate limits):**

Google rate-limits unauthenticated syncs. Set up git cookies:

1. Visit https://android.googlesource.com
2. Click "Generate Password"
3. Authenticate and follow the "Configure Git" instructions
4. Copy and run the provided shell script

**Global git config:**

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

**Package requests:**

Root access is not provided. If a system package is missing:

> "Hi, could you please install `libncurses5` via `sudo apt install`?"

Most tools can be installed locally in `~/bin` or via `pip install --user`.

**Plan extension:**

Each rental can be extended by 2 hours for free once via the dashboard. Use it when your build is nearly done.

## Features Enabled

- Nothing Camera with video recording fix (MySelly blobs, portrait/night working)
- Google Camera (from kleidione vendor)
- NGlyphs - glyph LED control (audio sync, recording LED, music visualizer, Glyph Converter)
- KernelSU with syscall tamper and full SUSFS (root hiding)
- Kali NetHunter - Wi-Fi monitor mode, HID attacks, mac80211 injection, WireGuard, HID gamepads
- NoMount path redirection subsystem
- MPTCP multipath TCP (mainline kernel feature)
- Dolby audio (Sony Dolby with spatial audio)
- Device as Webcam (USB UVC enabled)
- FP screen-off unlock enabled by default
- NOS 3.2 vibrator improvements
- Perf init script (CPU boost, schedutil, CPUSets, uclamp, IRQ affinity)
- SPAMMY_LOG_TAGS (cleaner logcat on user builds)
- OrangeFox recovery compatible (TARGET_NO_RECOVERY)
- LTO + O3 + ThinLTO + HWUI optimizations
- USB gadget reconfiguration with proper HID keyboard descriptor

## Credits

- [kleidione](https://github.com/kleidione) - device tree base, vendor blobs, FP fix, ghost touch fix, Dolby, Google Camera
- [DaViDev985](https://github.com/DaViDev985) - vendor blobs, camera sepolicy, NOS 3.2 fixes, NtOnlineConfig
- [smrth097](https://github.com/smrth097) - original Spacewar bringup, perf init, IRQ config, SPAMMY_LOG_TAGS
- [Jis G Jacob (StudioKeys)](https://github.com/StudioKeys-Dumps) - NGlyphs, recovery ADSP patch
- [William24hmar](https://github.com/William24hmar) - KSU-SUSFS kernel base, NetHunter configs
- [MySelly](https://github.com/MySelly) - working Nothing Camera APK
- [rodrig20](https://github.com/rodrig20) - USB gadget improvements
- [maxsteeel](https://github.com/maxsteeel) - NoMount kernel subsystem
- [QCerberusQ](https://github.com/QCerberusQ) - OrangeFox recovery for Spacewar
- [LineageOS](https://github.com/LineageOS) - hardware/nothing base
- [crDroid](https://github.com/crdroidandroid) - vendor blobs, camera APK, Bluetooth, sensor calibration libs
- [halogenOS](https://github.com/halogenOS) - Display brightness and Extra Dim config
- [VoltageOS](https://github.com/VoltageOS) - ROM platform
- [ServerHive](https://github.com/ServerHive-Development/guide) - build environment guide

## Useful Links

- Device tree: https://github.com/ang3lo-azevedo/android_device_nothing_Spacewar
- Kernel source: https://github.com/ang3lo-azevedo/android_kernel_nothing_sm7325
- Spacewar Development Telegram: Spacewar Development group
- ServerHive build guide: https://github.com/ServerHive-Development/guide
