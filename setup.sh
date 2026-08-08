#!/usr/bin/env bash
set -euo pipefail

echo "=== VoltageOS ServerHive Setup ==="
echo ""
echo "Git cookies for android.googlesource.com are required."
echo ""
echo "Get them by visiting https://android.googlesource.com in a browser:"
echo "  1. Click 'Generate Password' and authenticate"
echo "  2. Copy the entire shell script it gives you"
echo "  3. Save it to a file on your machine, then enter the path below"
echo "     Example: echo 'PASTE SCRIPT HERE' > /tmp/gitcookies.sh"
echo ""
read -p "Path to the cookie script file (or Enter to skip): " COOKIE_FILE < /dev/tty

if [ -z "$COOKIE_FILE" ] || [ ! -f "$COOKIE_FILE" ]; then
    echo "Cannot proceed without cookies. Save the script to a file and re-run."
    exit 1
fi
COOKIE_SCRIPT=$(cat "$COOKIE_FILE")
echo ""

read -p "SSH command [ssh nos4a2250@arcane.serverhive.in -p22]: " SSH_CMD < /dev/tty
SSH_CMD="${SSH_CMD:-ssh nos4a2250@arcane.serverhive.in -p22}"

if command -v sshpass &>/dev/null; then
    read -s -p "SSH password: " SSHPASS < /dev/tty; echo ""
    SSH() { sshpass -p "$SSHPASS" $SSH_CMD -- "$@"; }
else
    SSH() { $SSH_CMD -- "$@"; }
fi

echo ""
echo "Pushing git cookies to server..."
echo "$COOKIE_SCRIPT" | SSH "bash -s" 2>/dev/null && echo "  done" || { echo "  failed - check your SSH connection"; exit 1; }

echo ""
echo "GitHub PAT (scope: repo): https://github.com/settings/tokens"
read -s -p "GitHub PAT: " GHPAT < /dev/tty; echo ""

read -p "Build folder [voltageos]: " DIR < /dev/tty
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
    repo init -u https://github.com/VoltageOS/manifest.git -b 16.2 --git-lfs --depth=1
    mkdir -p .repo/local_manifests
    git clone -b 16.2 https://github.com/ang3lo-azevedo/voltageos-spacewar.git .repo/local_manifests
fi

echo "Syncing. This takes a while."
repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune

echo "Adding aliases..."
for RC in ~/.bashrc ~/.zshrc; do
    [ -f "$RC" ] || continue
    grep -q "alias build=" "$RC" 2>/dev/null || \
        echo "alias build='cd ~/$BUILD_DIR && source build/envsetup.sh && lunch voltage_Spacewar-bp4a-user && mka bacon'" >> "$RC"
    grep -q "alias sync="  "$RC" 2>/dev/null || \
        echo "alias sync='cd ~/$BUILD_DIR && repo sync -c -j\$(nproc) --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune'" >> "$RC"
done

echo "Setting up ccache..."
ccache -M 50G 2>/dev/null || echo "  ccache not available, skipping"

SETUP

echo ""
echo "Setup finished. Aliases are loaded: run 'sync' or 'build'."
