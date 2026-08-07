# VoltageOS for Nothing Phone (1) (Spacewar)

Local manifest for building VoltageOS on the Nothing Phone (1).

## Index

- [ServerHive Build Server](#serverhive-build-server)
  - [Quick Start](#quick-start)
  - [Persistent Sessions (Byobu)](#persistent-sessions-byobu)
  - [Package Requests](#package-requests)
- [Self-Hosted Setup](#self-hosted-setup)
  - [Prerequisites](#prerequisites)
- [Usage](#usage)
  - [GitHub Authentication](#github-authentication)
  - [Git Cookies](#git-cookies-recommended-not-necessary)
  - [Global Git Config](#global-git-config)
  - [Manual Setup](#manual-setup)
- [Included Projects](#included-projects)
- [How All the Pieces Were Found](#how-all-the-pieces-were-found)
- [Features Enabled](#features-enabled)
- [Troubleshooting](#troubleshooting)

## Included Projects

All trees are pulled automatically by `repo sync` after adding the local manifest.

| Path | Source repo | Branch | Purpose |
|------|-----------|--------|---------|
| `device/nothing/Spacewar` | `ang3lo-azevedo/android_device_nothing_Spacewar` | `voltage` | Board config, overlays, init, sepolicy |
| `kernel/nothing/sm7325` | `ang3lo-azevedo/android_kernel_nothing_sm7325` | `voltage-nethunter` | Linux 5.4.302, KSU-SUSFS, NetHunter |
| `vendor/nothing/Spacewar` | `DaViDev985/vendor_nothing_Spacewar` | `derp16.2` | Proprietary blobs (NOS 3.2) |
| `vendor/nothing/camera` | `DaViDev985/proprietary_vendor_nothing_camera` | `derp16` | Nothing Camera APK and libs |
| `hardware/nothing` | `ang3lo-azevedo/android_hardware_nothing` | `16.2-nglyphs` | NGlyphs, fingerprint HAL |
| `hardware/dolby` | `kleidione/hardware_dolby` | `bp4a` | Dolby audio processing |
| `vendor/google/GoogleCamera` | `kleidione/vendor_google_GoogleCamera` | `bp3a` | Google Camera APK |
| `vendor/voltage-priv/keys` | `ang3lo-azevedo/vendor_voltage-priv_keys` | `main` | ROM signing keys (private) |

To clone a tree for local development:

```bash
git clone -b <branch> https://github.com/<source repo> <path>
# Example:
git clone -b voltage https://github.com/ang3lo-azevedo/android_device_nothing_Spacewar device/nothing/Spacewar
```

## How All the Pieces Were Found

Every custom ROM is a puzzle where you find and combine pieces from different maintainers. Here is how each piece of this ROM was discovered and assembled.

### The Platform: VoltageOS

Started by searching GitHub for "VoltageOS manifest" to find the official platform source. The [VoltageOS manifest repo](https://github.com/VoltageOS/manifest) lists all the repositories that make up the ROM. Using `git clone` of that manifest gives you the base: frameworks, system apps, build tools, everything from AOSP plus VoltageOS customizations.

### The Device Tree: kleidione as Base

Next, you need a device tree that tells the build system how to compile for the Nothing Phone (1). Searched GitHub for "nothing Spacewar device tree" and found several maintainers. [kleidione's](https://github.com/kleidione/device_nothing_Spacewar) `bp4a` branch was the most complete with vibrator fixes, FP permissions, power profiles, and ghost touch fixes straight from the NOS 3.2 kernel source.

### The Vendor Blobs: DaViDev985

Without proprietary files (camera libs, sensors, audio DSP, fingerprint firmware), the ROM boots but nothing works. Found [DaViDev985's vendor repo](https://github.com/DaViDev985/vendor_nothing_Spacewar) on the `derp16.2` branch. These blobs came from a NOS 3.2 factory image extracted with `extract-files.sh`. His was the only vendor that booted cleanly; others had keymaster version mismatches that broke encrypted storage.

### The Camera: DaViDev985 + Arcsoft Libs

DaViDev985's [camera vendor repo](https://github.com/DaViDev985/proprietary_vendor_nothing_camera) has the Nothing Camera APK and companion libs. But the APK `dlopen`s arcsoft processing libs at runtime, and they are not listed anywhere in the build system. The fix was found by running `adb logcat` on a booted ROM and grepping for "dlopen failed" -- 14 arcsoft libs were failing to load. Added them to `public.libraries.txt` and `file_contexts` in the device tree to whitelist and label them for SELinux.

### The Kernel: William24hmar

The stock kernel lacks KernelSU and SUSFS for root hiding. Found [William24hmar's kernel](https://github.com/William24hmar/nothing_android_kernel_sm7325) `KSU-SUSFS` branch with KSU syscall tamper and full SUSFS. Then cherry-picked his `Nethunter` branch for Wi-Fi monitor mode and HID attacks, his `module` branch for Re:Kernel and log silencing, and his `Test` branch for security fixes and critical task boost. The kernel assembly was: `KSU-SUSFS` (base) + `Nethunter` (configs) + `module` (proc_ops, NF tables, silencing) + `Test` (security fixes, binder boost, TCP annotations).

### The Hardware HAL: NGlyphs from StudioKeys

Nothing Phone (1) has glyph LEDs that need a HAL. DaViDev985's [hardware/nothing repo](https://github.com/DaViDev985/android_hardware_nothing) had a ParanoidGlyph implementation that required root. Found [StudioKeys-Dumps' fork](https://github.com/StudioKeys-Dumps/hardware_nothing) with NGlyphs -- a system app replacement that works without root and has audio-glyph sync, music visualizer, and recording LED. Cherry-picked 20 commits from their `waterlily-qpr2` branch into our hardware/nothing tree.

### Cherry-Picking Improvements

Every active Spacewar maintainer has their own device tree. Rather than fork one, improvements were cherry-picked from each:

- **[smrth097](https://github.com/smrth097/android_device_nothing_Spacewar)** `16.2-clean`: perf init script (CPU boost, schedutil tuning, uclamp), IRQ balance config (prevents GPU micro-stutter), WiFi concurrent STA (hotspot + WiFi), SPAMMY_LOG_TAGS (cleaner logcat), QTI vndfwk (fixes CNE networking)
- **[crDroid](https://github.com/crdroidandroid/android_device_nothing_Spacewar)** `16.0`: NOS 3.2 mixer paths (camcorder audio fix), Bluetooth ASHA/AptX/HD/Adaptive/LDAC codecs, sensor calibration libs, camera soong configs, audio skip_speaker fix
- **[halogenOS](https://github.com/halogenOS/android_device_nothing_Spacewar)** `XOS-16.2`: linear-nits brightness mapping with Extra Dim evening dimmer config

### How to Find This Stuff Yourself

0. **Start with LineageOS**: For a first build, use [LineageOS device trees](https://github.com/LineageOS) as your base. They are the most compatible out of the box, have proper SELinux policies, and are actively maintained. Clone their device, kernel, and vendor trees, get a booting build, then cherry-pick improvements from other maintainers one at a time. This way you always have a known-good fallback. Once everything works, switch to a custom base.
1. **GitHub search**: `nothing spacewar device tree`, `sm7325 kernel ksu`, `nothing vendor spacewar`
2. **Telegram groups**: "Spacewar Development" group where maintainers share their repos
3. **Other ROM manifests**: Look at `crDroid`, `EvolutionX`, `LineageOS` manifests. They have `*.dependencies` files that list what repos they use
4. **Build errors are clues**: When a build fails with "missing file X", search GitHub for that filename. The repo containing it is the one you are missing
5. **logcat debug**: Flash a booting build, `adb logcat | grep -i "failed\|error\|missing"` to find runtime issues like missing libs or SELinux denials

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


## ServerHive Build Server

This project is designed to build on [ServerHive](https://github.com/ServerHive-Development/guide) bare-metal servers. A single rental gives you a machine with all build tools pre-installed: browser IDE (VS Code), monitoring dashboard, mobile app, and Drive for storage.

Rent a server at [t.me/ServerRentals](https://t.me/ServerRentals). Connection details are sent to your dashboard after provisioning.

### Quick Start

```bash
curl -sSL https://raw.githubusercontent.com/ang3lo-azevedo/local_manifests/16.2/setup.sh | bash
```

The script handles everything: terminfo, git config, repo init, manifest, sync, and aliases. Git cookies are not set up (optional, see [Git Cookies](#git-cookies-recommended-not-necessary)). Needs `sshpass` locally (`apt install sshpass`).

After setup, SSH in and run `sync` or `build`.

### Persistent Sessions (Byobu)

ServerHive uses Byobu. Your build keeps running even if you disconnect.

```bash
# Detach: F6 or Ctrl+A then D
# New window: F2
# Navigate windows: F3 (previous) / F4 (next)
# Reattach after disconnect: byobu
```

### Package Requests

Root access is not provided. If a system package is missing:

> "Hi, could you please install `libncurses5` via `sudo apt install`?"

Most tools can be installed locally in `~/bin` or via `pip install --user`.

## Self-Hosted Setup

If you are NOT using ServerHive, the following is required on your own machine before building.

### Prerequisites

- Android `repo` tool installed
- At least 200GB free disk space

## Usage

### GitHub Authentication

The `vendor/voltage-priv/keys` repository is **private** and used for ROM signing. Only the repo owner has access to it. Everyone else should remove or replace it.

#### Option A: Remove or replace the signing keys (recommended)

If you are not the repo owner, you cannot access the private keys. Pick one:

| Method | What to do |
|--------|------------|
| **Remove it** | Edit `.repo/local_manifests/voltage_manifest.xml` and delete both the `<remove-project>` and `<project>` lines for `vendor/voltage-priv/keys` |
| **Replace it** | Clone the [official keys template](https://github.com/VoltageOS/vendor_voltage-priv_keys), generate your own, and push to your repo |

To generate your own keys:

```bash
croot && git clone https://github.com/VoltageOS/vendor_voltage-priv_keys vendor/voltage-priv/keys
cd vendor/voltage-priv/keys
./keys.sh
```

Push the generated `vendor/voltage-priv/keys` folder (with all `.pk8`, `.x509.pem`, `keys.mk`, etc.) to a new git repo, then update the project entry in `voltage_manifest.xml` to point to it.

> Test keys are sufficient for unofficial builds. The build system skips missing keys automatically.

#### Option B: Use the private keys repo (ang3lo-azevedo only)

Only the repo owner has access to this repo. Authenticate with one of:

**GitHub CLI:**

```bash
gh auth login --hostname github.com --git-protocol https
gh auth setup-git
```

Verify: `git ls-remote https://github.com/ang3lo-azevedo/vendor_voltage-priv_keys.git`

**Manual PAT:**

1. Create a token at https://github.com/settings/tokens with `repo` scope
2. Store the credentials:

```bash
git config --global credential.helper store
read -p "GitHub username: " GH_USER
read -s -p "GitHub PAT: " GH_PAT; echo
printf "protocol=https\nhost=github.com\nusername=%s\npassword=%s\n\n" "$GH_USER" "$GH_PAT" | git credential approve
```

### Git Cookies (recommended, not necessary)

Google rate-limits unauthenticated repo syncs, sometimes causing `429 Too Many Requests` errors. Setting up git cookies prevents this. It is not strictly required but highly recommended to avoid sync interruptions.

1. Visit https://android.googlesource.com
2. Click "Generate Password"
3. Authenticate and follow the "Configure Git" instructions
4. Copy and run the provided shell script

### Global Git Config

`repo` uses git internally. Git refuses to operate without `user.name` and `user.email` set:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Manual Setup

If you prefer to set up manually:

#### 1. Initialize the repo

```bash
repo init -u https://github.com/VoltageOS/manifest.git -b 16.2 --git-lfs
```

#### 2. Add the local manifest

```bash
git clone https://github.com/ang3lo-azevedo/local_manifests.git .repo/local_manifests
```

**Optional build aliases** -- add these to `~/.zshrc` for convenience (the one-line setup does this automatically):

```bash
alias sync='cd ~/voltageos && repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune'
alias build='cd ~/voltageos && source build/envsetup.sh && lunch voltage_Spacewar-bp4a-user && mka bacon'
```

#### 3. Sync

```bash
repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune
```

Or run `sync` if you added the alias above.

#### 4. Build

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

These values are set automatically by the device tree and ROM build system. The output zip filename follows the format:

```
voltage-{VERSION}-Spacewar-{DATE}-{TIME}-{BUILD_TYPE}.zip
```

Example: `voltage-5.11-EOL-Spacewar-20260806-2155-UNOFFICIAL.zip`

Output goes to `out/target/product/Spacewar/`.

## Features Enabled

- Nothing Camera with video recording fix (photo/video working, portrait via Google Camera)
- Google Camera (from kleidione vendor, portrait mode works there)
- NGlyphs - glyph LED control (audio sync, recording LED, music visualizer, Glyph Converter)
- KernelSU with syscall tamper and full SUSFS (root hiding)
- Kali NetHunter - Wi-Fi monitor mode, HID attacks, mac80211 injection, WireGuard, HID gamepads
- NoMount path redirection subsystem
- MPTCP multipath TCP
- Dolby audio with spatial audio
- Device as Webcam (USB UVC)
- FP screen-off unlock enabled by default
- Persistent taskbar (config_enableTaskbar overlay)
- QTI vndfwk / CNE networking support
- WiFi concurrent STA (hotspot + WiFi simultaneously)
- Perf init script (CPU boost, schedutil, CPUSets, uclamp, IRQ affinity)
- SPAMMY_LOG_TAGS (cleaner logcat on user builds)
- NOS 3.2 vibrator, post_boot.sh, and mixer paths
- Extra Dim display config (linear-nits brightness mapping)
- Bluetooth codecs: ASHA, AptX/HD/Adaptive, LDAC, AAC
- OrangeFox recovery compatible (TARGET_NO_RECOVERY)
- LTO + O3 + ThinLTO + HWUI optimizations

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

### "missing or unsuitable terminal: xterm-ghostty" (or similar)

If your terminal shows errors like `missing or unsuitable terminal`, `unknown terminal type`, or `terminal is not fully functional` when SSHing, your remote server does not have your terminal's terminfo entry. This affects Ghostty, Kitty, WezTerm, Alacritty, and other modern terminals.

See the [Ghostty terminfo docs](https://ghostty.org/docs/help/terminfo#ssh) for more details on this issue.

**Fix:** Push your terminal's terminfo to the server:

```bash
infocmp -x $TERM | ssh user@server -- tic -x -
```

The `tic` command may warn about older versions treating the description as an alias - this is safe to ignore.

If `tic` cannot write to the system location, it falls back to `~/.terminfo`. For servers without `tic`, set a fallback terminal in your SSH config (`~/.ssh/config`):

```
Host example.com
  SetEnv TERM=xterm-256color
```

Note: the fallback approach loses advanced terminal features like colored underlines and styled text.

### Missing proprietary files

Some prebuilt binaries may be missing from the vendor tree. Verify the branch exists and has the required files. Comment out missing modules from `Android.bp` if necessary.

### Duplicate sysprop assignments (audio)

If the build fails with `found duplicate sysprop assignments` for `ro.config.ringtone`, `ro.config.notification_sound`, or `ro.config.alarm_alert`, the ROM and device tree are both setting these properties on the product partition. Fix by using weak assignment in the ROM config:

```bash
sed -i 's/ro.config.ringtone=/ro.config.ringtone?=/; s/ro.config.alarm_alert=/ro.config.alarm_alert?=/; s/ro.config.notification_sound=/ro.config.notification_sound?=/' vendor/voltage/audio/audio.mk
```

This allows the device tree to override the ROM defaults with Nothing tones without a build conflict.

## Credits

- [kleidione](https://github.com/kleidione) - device tree base, vendor blobs, FP fix, ghost touch fix, Dolby, Google Camera
- [DaViDev985](https://github.com/DaViDev985) - vendor blobs, camera sepolicy, NOS 3.2 fixes, NtOnlineConfig
- [smrth097](https://github.com/smrth097) - original Spacewar bringup, perf init, IRQ config, SPAMMY_LOG_TAGS
- [Jis G Jacob (StudioKeys)](https://github.com/StudioKeys-Dumps) - NGlyphs, recovery ADSP patch
- [William24hmar](https://github.com/William24hmar) - KSU-SUSFS kernel base, NetHunter configs
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
- Hardware/nothing: https://github.com/ang3lo-azevedo/android_hardware_nothing
- Local manifests: https://github.com/ang3lo-azevedo/local_manifests
- VoltageOS platform: https://github.com/VoltageOS
- ServerHive build guide: https://github.com/ServerHive-Development/guide
