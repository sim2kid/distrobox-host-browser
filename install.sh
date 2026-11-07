#!/bin/sh
# Install the host-browser bridge. Run inside the distrobox container:
#   sh install.sh
# Needs sudo. Writes only container-local paths (/usr/local, /usr/share, /etc).
set -eu

if [ ! -e /run/.containerenv ] && [ -z "${CONTAINER_ID:-}" ]; then
    echo "install.sh: run this inside the distrobox container, not on the host." >&2
    exit 1
fi

here=$(cd "$(dirname "$0")" && pwd)
state=/usr/local/share/host-browser

sudo mkdir -p "$state"

# Remember what /usr/local/bin/xdg-open was so uninstall.sh can restore it.
if [ -L /usr/local/bin/xdg-open ] && [ ! -e "$state/xdg-open.orig-target" ]; then
    readlink /usr/local/bin/xdg-open | sudo tee "$state/xdg-open.orig-target" >/dev/null
fi

sudo install -Dm755 "$here/bin/host-open" /usr/local/bin/host-open
sudo ln -sf host-open /usr/local/bin/xdg-open

sudo install -Dm644 "$here/share/host-browser.desktop" /usr/share/applications/host-browser.desktop

if [ -e /etc/xdg/mimeapps.list ] && ! cmp -s "$here/share/mimeapps.list" /etc/xdg/mimeapps.list \
        && [ ! -e "$state/mimeapps.list.orig" ]; then
    sudo cp /etc/xdg/mimeapps.list "$state/mimeapps.list.orig"
fi
sudo install -Dm644 "$here/share/mimeapps.list" /etc/xdg/mimeapps.list

sudo update-desktop-database /usr/share/applications 2>/dev/null || true

# The one file that must be visible to the host: host-open runs it there via
# distrobox-host-exec to raise the browser window. Home is shared, so it goes
# in a directory of its own.
install -Dm755 "$here/share/raise-browser.sh" "$HOME/.local/share/host-browser/raise-browser.sh"

# For tools that look for x-www-browser / sensible-browser.
sudo update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/local/bin/host-open 50 >/dev/null
sudo update-alternatives --set x-www-browser /usr/local/bin/host-open >/dev/null

echo "Installed. Fully quit and reopen apps (e.g. Claude Desktop) so they re-check the default browser."
