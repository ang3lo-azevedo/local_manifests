# Voltage ROM - Local Manifest

This directory contains the local manifest configuration for building the Voltage ROM for the Nothing Phone (Spacewar).

## Prerequisites

- Android repo tool installed
- Git configured on your system
- GitHub authentication set up (see GitHub Login section)

## Usage

### 1. Initialize the Repo

If you haven't already initialized repo:

```bash
repo init -u <main-manifest-repo> -b <branch>
```

### 2. Add This Local Manifest

This manifest should be placed in `.repo/local_manifests/` directory. The repos folder structure will be:

```plain
.repo/
├── manifests/              # Main platform manifest
└── local_manifests/        # Your custom manifests (this directory)
    ├── voltage_manifest.xml
    └── README.md
```

### 3. Sync Repositories

```bash
repo sync -c -j24 --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune
```

### 4. Build the ROM

Setup the build environment:

```bash
source build/envsetup.sh
breakfast Spacewar
```

Or compile directly:

```bash
brunch Spacewar
```

## GitHub Login

This manifest includes private repositories that require authentication.

### Option A: GitHub CLI (Recommended) - Paste Token in Terminal

Install GitHub CLI:

```bash
# Ubuntu/Debian
sudo apt install gh

# macOS
brew install gh
```

Authenticate by pasting your token in the terminal:

```bash
gh auth login --hostname github.com --git-protocol https
gh auth setup-git
```

When prompted, choose the token-based login flow and paste the token into the terminal.

Verify access:

```bash
git ls-remote https://github.com/ang3lo-azevedo/vendor_voltage-priv_keys.git
```

### Option B: Manual Personal Access Token (PAT) Setup

1. Create a token on GitHub:
   - Go to https://github.com/settings/tokens
   - Click "Generate new token" → "Generate new classic token"
   - Select scopes: `repo` (full control of private repositories)
   - Copy the token

2. Store credentials:

```bash
git config --global credential.helper store
read -p "GitHub username: " GH_USER
read -s -p "GitHub PAT: " GH_PAT; echo
printf "protocol=https\nhost=github.com\nusername=%s\npassword=%s\n\n" "$GH_USER" "$GH_PAT" | git credential approve
```

3. Verify access:

```bash
git ls-remote https://github.com/ang3lo-azevedo/vendor_voltage-priv_keys.git
```

## Included Projects

This manifest syncs the following repositories:

| Project | Path | Repository | Branch |
|---------|------|------------|--------|
| Voltage Private Keys | `vendor/voltage-priv/keys` | `ang3lo-azevedo/vendor_voltage-priv_keys` | `main` |
| Device Tree | `device/nothing/Spacewar` | `ang3lo-azevedo/android_device_nothing_Spacewar` | `voltage` |
| Vendor Blobs | `vendor/nothing/Spacewar` | `kleidione/vendor_nothing_Spacewar` | `bp4a` |
| Camera Blobs | `vendor/nothing/camera` | `DaViDev985/proprietary_vendor_nothing_camera` | (default) |
| Kernel | `kernel/nothing/sm7325` | `William24hmar/nothing_android_kernel_sm7325` | `Rebase-New` |
| Hardware | `hardware/nothing` | `StudioKeys-Dumps/hardware_nothing` | `waterlily-qpr2` |
| Dolby Audio | `hardware/dolby` | `smrth097/hardware_dolby` | `16.0` |
| ParanoidGlyph App | `packages/apps/ParanoidGlyph` | `smrth097/packages_apps_ParanoidGlyph` | `16` |

## Troubleshooting

### "Cannot locate config makefile"

This happens if repos didn't sync properly. Re-run:

```bash
repo sync -c -j24 --force-sync
```

### "Cannot fetch repository"

Ensure GitHub authentication is set up properly. Test with:

```bash
git ls-remote https://github.com/ang3lo-azevedo/vendor_voltage-priv_keys.git
```

### Missing binary files during build

Some prebuilt binaries may be missing from incomplete proprietary trees. Solution:

- Verify the branch exists and has the required files
- Comment out missing modules from Android.bp if necessary

### "revision refs/tags/X not found"

This means the specified branch/tag doesn't exist in that repository. Update the manifest with the correct revision.

## Build Configuration

The build will generate:

```plain
VOLTAGE_VERSION=5.8-Spacewar-YYYYMMDD-HHMM-UNOFFICIAL
BUILD_ID=BP4A.251205.006
TARGET_PRODUCT=voltage_Spacewar
TARGET_BUILD_VARIANT=user
```

Output files will be in the `out/` directory.

## Support

For issues with repos or the build process, check:

- Device tree: [android_device_nothing_Spacewar](https://github.com/ang3lo-azevedo/android_device_nothing_Spacewar)
- Kernel: [nothing_android_kernel_sm7325](https://github.com/William24hmar/nothing_android_kernel_sm7325)
- Main ROM: Voltage ROM official channels
