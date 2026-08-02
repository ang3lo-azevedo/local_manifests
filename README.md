# VoltageOS for Nothing Phone (1) (Spacewar)

Local manifest for building VoltageOS on the Nothing Phone (1).

## Included Projects

| Path | Repository | Branch |
|------|------------|--------|
| `device/nothing/Spacewar` | `ang3lo-azevedo/android_device_nothing_Spacewar` | `voltage` |
| `kernel/nothing/sm7325` | `ang3lo-azevedo/android_kernel_nothing_sm7325` | `voltage` |
| `vendor/nothing/Spacewar` | `DaViDev985/vendor_nothing_Spacewar` | `derp16.2` |
| `vendor/nothing/camera` | `DaViDev985/proprietary_vendor_nothing_camera` | `derp16` |
| `hardware/nothing` | `ang3lo-azevedo/android_hardware_nothing` | `16.2-nglyphs` |
| `hardware/dolby` | `kleidione/hardware_dolby` | `bp4a` |
| `vendor/voltage-priv/keys` | `ang3lo-azevedo/vendor_voltage-priv_keys` | `main` |

### Tree Sources

The device tree (`android_device_nothing_Spacewar`) merges improvements from:

- **kleidione/bp4a** - base with NOS 3.2 fixes (vibrator, FP, power profile)
- **DaViDev985/derp16.2** - NOS 3.2 post_boot.sh, sepolicy, FP unlock
- **smrth097/16.2-clean** - overlay improvements
- **crDroid/16.0** - Bluetooth, radio, audio mixer improvements
- **halogenOS/XOS-16.2** - Display brightness and Extra Dim config

The hardware/nothing tree (`android_hardware_nothing`) is based on:

- **DaViDev985/derp16.2** - base with NtOnlineConfig stub (required for Nothing Camera)
- **StudioKeys-Dumps/waterlily-qpr2** - NGlyphs patches (20 commits cherry-picked)

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

Copy `voltage_manifest.xml` into `.repo/local_manifests/`:

```bash
mkdir -p .repo/local_manifests
cp voltage_manifest.xml .repo/local_manifests/
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

- NGlyphs (glyph LED control, audio sync, recording LED, no root needed)
- Nothing Camera with video recording fix
- Dolby audio
- Device as Webcam
- FP screen-off unlock
- NOS 3.2 vibrator improvements
- LTO + O3 + ThinLTO optimizations

## Credits

- [kleidione](https://github.com/kleidione) - device tree base, FP fix, ghost touch fix
- [DaViDev985](https://github.com/DaViDev985) - vendor blobs, camera, NOS 3.2 fixes
- [smrth097](https://github.com/smrth097) - original Spacewar bringup
- [Jis G Jacob (StudioKeys)](https://github.com/StudioKeys-Dumps) - NGlyphs, recovery ADSP patch
- [William24hmar](https://github.com/William24hmar) - kernel source
- [LineageOS](https://github.com/LineageOS) - hardware/nothing base
- [crDroid](https://github.com/crdroidandroid) - Bluetooth and radio improvements
- [halogenOS](https://github.com/halogenOS) - Display brightness and Extra Dim config
- [VoltageOS](https://github.com/VoltageOS) - ROM platform
- [ServerHive](https://github.com/ServerHive-Development/guide) - build environment guide

## Useful Links

- Device tree: https://github.com/ang3lo-azevedo/android_device_nothing_Spacewar
- Kernel source: https://github.com/ang3lo-azevedo/android_kernel_nothing_sm7325
- Spacewar Development Telegram: Spacewar Development group
- ServerHive build guide: https://github.com/ServerHive-Development/guide
