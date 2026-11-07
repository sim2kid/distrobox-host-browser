#!/bin/sh
# Undo install.sh. Run inside the distrobox container: sh uninstall.sh
set -eu

if [ ! -e /run/.containerenv ] && [ -z "${CONTAINER_ID:-}" ]; then
    echo "uninstall.sh: run this inside the distrobox container, not on the host." >&2
    exit 1
fi

state=/usr/local/share/host-browser

sudo update-alternatives --remove x-www-browser /usr/local/bin/host-open 2>/dev/null || true

sudo rm -f /usr/share/applications/host-browser.desktop /usr/local/bin/host-open

if [ -e "$state/mimeapps.list.orig" ]; then
    sudo cp "$state/mimeapps.list.orig" /etc/xdg/mimeapps.list
else
    sudo rm -f /etc/xdg/mimeapps.list
fi

if [ -e "$state/xdg-open.orig-target" ]; then
    sudo ln -sf "$(cat "$state/xdg-open.orig-target")" /usr/local/bin/xdg-open
else
    sudo rm -f /usr/local/bin/xdg-open
fi

rm -rf "$HOME/.local/share/host-browser"
sudo rm -rf "$state"
sudo update-desktop-database /usr/share/applications 2>/dev/null || true

echo "Uninstalled."
