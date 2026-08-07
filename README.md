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

## Prerequisites

- Android `repo` tool installed
- At least 200GB free disk space

## ServerHive Build Server

This project is designed to build on [ServerHive](https://github.com/ServerHive-Development/guide) bare-metal servers. A single rental gives you a fresh machine with all build tools pre-installed. Key features include a browser-based IDE (VS Code), real-time monitoring dashboard, mobile management app, and Drive for build storage.

### Quick Start

Rent a ServerHive machine at https://serverhive.com, then SSH in:

```bash
ssh username@server.serverhive.com -p 22
```

### Persistent Sessions (Byobu)

ServerHive uses Byobu as the default terminal multiplexer. Your build keeps running even if you disconnect.

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

### Plan Extension

Each rental can be extended by 2 hours for free once via the dashboard. Use it when your build is nearly done.

## Usage

### GitHub Authentication

The `vendor/voltage-priv/keys` repository is **private** and used for ROM signing. Only the repo owner has access to it. Everyone else should remove or replace it.

#### Option A: Remove or replace the signing keys (recommended)

If you are not the repo owner, you cannot access the private keys. Pick one:

| Method | What to do |
|--------|------------|
| **Remove it** | Edit `.repo/local_manifests/voltage_manifest.xml` and delete both the `<remove-project>` and `<project>` lines for `vendor/voltage-priv/keys` |
| **Replace it** | Create your own keys repo (see [AOSP signing docs](https://source.android.com/docs/core/ota/sign_builds)) and change the project entry to point to yours |

The build will use **test keys** if no custom keys are provided. This is fine for personal use.

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

### Global Git Config (required)

`repo` uses git internally. Git refuses to operate without `user.name` and `user.email` set:

### One-Line Setup

Run this from your local machine (not the server). It prompts for your SSH details and GitHub PAT, then does everything automatically:

```bash
curl -sSL https://raw.githubusercontent.com/ang3lo-azevedo/local_manifests/16.2/setup.sh | bash
```

The script handles: pushing terminfo to the server, configuring git credentials, initializing the repo, cloning local manifests, syncing sources, and adding build aliases. Git cookies are not set up by the script (they are optional but recommended, see above). You only need `sshpass` installed locally (`apt install sshpass`).

After setup, SSH in and run:

```bash
source ~/.zshrc       # load aliases
sync-voltage          # update sources
build-voltage         # build the ROM
```

### Manual Setup

If you prefer to set up manually:

#### 1. Initialize the repo

```bash
repo init -u https://github.com/VoltageOS/manifest.git -b bp4a
```

#### 2. Add the local manifest

```bash
git clone https://github.com/ang3lo-azevedo/local_manifests.git .repo/local_manifests
```

#### 3. Sync

```bash
repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune
```

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

### Build Aliases

Add these to `~/.zshrc` (the one-line setup does this for you):

```bash
alias sync-voltage='cd ~/voltageos && repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune'
alias build-voltage='cd ~/voltageos && source build/envsetup.sh && lunch voltage_Spacewar-bp4a-user && mka bacon'
```

## Build Configuration

```
VOLTAGE_VERSION=5.8-Spacewar-YYYYMMDD-HHMM-UNOFFICIAL
BUILD_ID=BP4A.251205.006
TARGET_PRODUCT=voltage_Spacewar
TARGET_BUILD_VARIANT=user
```

Output goes to `out/target/product/Spacewar/`.

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
- [MySelly](https://github.com/MySelly) - working Nothing Camera APK
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
