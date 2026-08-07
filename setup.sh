#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m' GREEN='\033[0;32m' CYAN='\033[0;36m' NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════╗"
echo -e "║  VoltageOS ServerHive One-Click Setup  ║"
echo -e "╚══════════════════════════════════════╝${NC}"
echo ""

read -p "SSH command  [ssh nos4a2250@arcane.serverhive.in -p22]: " SSH_CMD
SSH_CMD="${SSH_CMD:-ssh nos4a2250@arcane.serverhive.in -p22}"

if command -v sshpass &>/dev/null; then
    read -s -p "SSH password: " SSHPASS; echo ""
    SSH() { sshpass -p "$SSHPASS" $SSH_CMD -- "$@"; }
else
    SSH() { $SSH_CMD -- "$@"; }
fi

echo ""
echo -e "${CYAN}GitHub PAT (scope: repo) — https://github.com/settings/tokens${NC}"
read -s -p "GitHub PAT:   " GHPAT; echo ""

read -p "Build folder  [voltageos]: " DIR
DIR="${DIR:-voltageos}"

# ── Ghostty terminfo ────────────────────────────────
echo ""
echo -e "${GREEN}[1/4] Ghostty terminfo...${NC}"
if infocmp -x xterm-ghostty &>/dev/null 2>&1; then
    infocmp -x xterm-ghostty | SSH "tic -x -" 2>/dev/null && \
        echo "  done" || echo "  (skipped — server may already have it)"
else
    echo "  (skipped — not running in Ghostty)"
fi

# ── Remote setup ─────────────────────────────────────
echo -e "${GREEN}[2/4] Running server setup...${NC}"

SSH "GH_PAT=$GHPAT BUILD_DIR=$DIR bash -s" << 'SETUP'
set -euo pipefail
G='\033[0;32m' N='\033[0m'

echo -e "${G}Configuring git...${N}"
git config --global user.name  "VoltageOS Builder"  2>/dev/null || true
git config --global user.email "builder@voltageos.local" 2>/dev/null || true
git config --global credential.helper store 2>/dev/null || true
printf "protocol=https\nhost=github.com\nusername=voltage-builder\npassword=%s\n\n" \
    "$GH_PAT" | git credential approve 2>/dev/null || true

echo -e "${G}Initializing ~/${BUILD_DIR}...${N}"
mkdir -p ~/"$BUILD_DIR"
cd ~/"$BUILD_DIR"

if [ ! -f .repo/manifest.xml ]; then
    repo init -u https://github.com/VoltageOS/manifest.git -b bp4a --depth=1
    mkdir -p .repo/local_manifests
    git clone -b 16.2 https://github.com/ang3lo-azevedo/local_manifests.git .repo/local_manifests
fi

echo -e "${G}Syncing sources (grab a coffee)...${N}"
repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune

echo -e "${G}Adding aliases...${N}"
for RC in ~/.bashrc ~/.zshrc; do
    [ -f "$RC" ] || continue
    grep -q "build-voltage" "$RC" 2>/dev/null || \
        echo "alias build-voltage='cd ~/$BUILD_DIR && source build/envsetup.sh && lunch voltage_Spacewar-bp4a-user && mka bacon'" >> "$RC"
    grep -q "sync-voltage"  "$RC" 2>/dev/null || \
        echo "alias sync-voltage='cd ~/$BUILD_DIR && repo sync -c -j\$(nproc) --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune'" >> "$RC"
done

echo ""
echo -e "${G}════════════════════════════════════"
echo -e "  Setup complete!"
echo -e "  source ~/.zshrc"
echo -e "  sync-voltage   (update sources)"
echo -e "  build-voltage  (build ROM)"
echo -e "════════════════════════════════════${N}"
SETUP

echo ""
echo -e "${GREEN}Done. SSH in and type 'build-voltage'.${NC}"
