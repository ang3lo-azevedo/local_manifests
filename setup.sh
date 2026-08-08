#!/usr/bin/env bash
set -euo pipefail

# Load .env if present
if [ -f .env ]; then
    set -a; source .env; set +a
    echo "Loaded .env"
elif [ -f ~/.config/voltageos-setup.env ]; then
    set -a; source ~/.config/voltageos-setup.env; set +a
    echo "Loaded ~/.config/voltageos-setup.env"
fi

echo "=== VoltageOS ServerHive Setup ==="
echo ""

if [ -z "${GS_COOKIE:-}" ]; then
    echo "Git cookies for android.googlesource.com are required."
    echo ""
    echo "  1. Visit https://android.googlesource.com in a browser"
    echo "  2. Click 'Generate Password' and authenticate"
    echo "  3. Look for the line between 'tr , \\\\t <<\\__END__' and '__END__'"
    echo "     Copy ONLY the first one, which looks like:"
    echo "     android.googlesource.com,FALSE,/,TRUE,2147483647,o,git-you=1//..."
    echo ""
    read -p "Paste that single cookie line: " GS_COOKIE < /dev/tty
    if [ -z "$GS_COOKIE" ]; then
        echo "Cannot proceed without cookies. Get the line from the link above and re-run."
        exit 1
    fi
    echo ""
fi

if [ -z "${SSH_CMD:-}" ]; then
    read -p "SSH command [ssh nos4a2250@arcane.serverhive.in -p22]: " SSH_CMD < /dev/tty
fi
SSH_CMD="${SSH_CMD:-ssh nos4a2250@arcane.serverhive.in -p22}"

if command -v sshpass &>/dev/null; then
    if [ -z "${SSHPASS:-}" ]; then
        read -s -p "SSH password: " SSHPASS < /dev/tty; echo ""
    fi
    SSH() { sshpass -p "$SSHPASS" $SSH_CMD -- "$@"; }
else
    SSH() { $SSH_CMD -- "$@"; }
fi

if [ -z "${GS_COOKIE_SENT:-}" ]; then
    echo ""
    echo "Pushing git cookies to server..."
    echo "$GS_COOKIE" | grep -q "android.googlesource.com" || { echo "  invalid cookie line - must start with android.googlesource.com"; exit 1; }
    echo "$GS_COOKIE" | SSH "tee -a ~/.gitcookies > /dev/null && chmod 0600 ~/.gitcookies && git config --global http.cookiefile ~/.gitcookies && echo '  done'"
    GS_COOKIE_SENT=1
fi

if [ -z "${GHPAT:-}" ]; then
    echo ""
    echo "GitHub PAT (scope: repo): https://github.com/settings/tokens"
    read -s -p "GitHub PAT: " GHPAT < /dev/tty; echo ""
fi

if [ -z "${DIR:-}" ]; then
    read -p "Build folder [voltageos]: " DIR < /dev/tty
fi
DIR="${DIR:-voltageos}"

echo ""
if [ -z "${SKIP_TERMINFO:-}" ]; then
    echo "Pushing terminfo..."
    if infocmp -x xterm-ghostty &>/dev/null 2>&1; then
        infocmp -x xterm-ghostty | SSH "tic -x -" 2>/dev/null && echo "  done" || echo "  skipped"
    else
        echo "  skipped (not in Ghostty)"
    fi
fi

echo "Running server setup..."
SSH "GH_PAT=$GHPAT BUILD_DIR=$DIR bash -s" << 'ENDREMOTE'
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

ENDREMOTE

echo ""
echo "Setup finished. Aliases are loaded: run 'sync' or 'build'."
