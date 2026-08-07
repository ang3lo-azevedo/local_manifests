#!/usr/bin/env bash
set -euo pipefail

echo "=== VoltageOS ServerHive Setup ==="
echo ""

read -p "SSH command [ssh nos4a2250@arcane.serverhive.in -p22]: " SSH_CMD
SSH_CMD="${SSH_CMD:-ssh nos4a2250@arcane.serverhive.in -p22}"

if command -v sshpass &>/dev/null; then
    read -s -p "SSH password: " SSHPASS; echo ""
    SSH() { sshpass -p "$SSHPASS" $SSH_CMD -- "$@"; }
else
    SSH() { $SSH_CMD -- "$@"; }
fi

echo ""
echo "GitHub PAT (scope: repo): https://github.com/settings/tokens"
read -s -p "GitHub PAT: " GHPAT; echo ""

read -p "Build folder [voltageos]: " DIR
DIR="${DIR:-voltageos}"

echo ""
echo "Pushing terminfo..."
if infocmp -x xterm-ghostty &>/dev/null 2>&1; then
    infocmp -x xterm-ghostty | SSH "tic -x -" 2>/dev/null && echo "  done" || echo "  skipped"
else
    echo "  skipped (not in Ghostty)"
fi

echo "Running server setup..."
SSH "GH_PAT=$GHPAT BUILD_DIR=$DIR bash -s" << 'SETUP'
set -euo pipefail

echo "Configuring git..."
git config --global user.name  "VoltageOS Builder"  2>/dev/null || true
git config --global user.email "builder@voltageos.local" 2>/dev/null || true
git config --global credential.helper store 2>/dev/null || true
printf "protocol=https\nhost=github.com\nusername=voltage-builder\npassword=%s\n\n" \
    "$GH_PAT" | git credential approve 2>/dev/null || true

echo "Setting up ~/${BUILD_DIR}..."
mkdir -p ~/"$BUILD_DIR"
cd ~/"$BUILD_DIR"

if [ ! -f .repo/manifest.xml ]; then
    repo init -u https://github.com/VoltageOS/manifest.git -b bp4a --depth=1
    mkdir -p .repo/local_manifests
    git clone -b 16.2 https://github.com/ang3lo-azevedo/local_manifests.git .repo/local_manifests
fi

echo "Syncing. This takes a while."
repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune

echo "Adding aliases..."
for RC in ~/.bashrc ~/.zshrc; do
    [ -f "$RC" ] || continue
    grep -q "build-voltage" "$RC" 2>/dev/null || \
        echo "alias build-voltage='cd ~/$BUILD_DIR && source build/envsetup.sh && lunch voltage_Spacewar-bp4a-user && mka bacon'" >> "$RC"
    grep -q "sync-voltage"  "$RC" 2>/dev/null || \
        echo "alias sync-voltage='cd ~/$BUILD_DIR && repo sync -c -j\$(nproc) --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune'" >> "$RC"
done

echo ""
echo "Done. Run: source ~/.zshrc && build-voltage"
SETUP

echo ""
echo "Setup finished. SSH in and run 'build-voltage'."
