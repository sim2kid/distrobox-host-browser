#!/bin/sh
# Runs on the host (called by host-open through distrobox-host-exec).
#
# KDE's focus-stealing prevention leaves a window that was launched without an
# activation token behind other windows. Ask KWin's windows runner to activate
# the browser's window instead. Waits up to ~9s so a cold-starting browser
# gets raised once its window exists.
#
# HOST_BROWSER_MATCH is a case-insensitive pattern for the window's class/icon
# (default: firefox).
pat=${HOST_BROWSER_MATCH:-firefox}

for _ in $(seq 1 30); do
    id=$(busctl --user --json=short call org.kde.KWin /WindowsRunner org.kde.krunner1 Match s "$pat" 2>/dev/null \
        | jq -r --arg p "$pat" '[.data[0][] | select(.[2] | test($p; "i"))][0][0] // empty' 2>/dev/null)
    if [ -n "$id" ]; then
        busctl --user call org.kde.KWin /WindowsRunner org.kde.krunner1 Run ss "$id" "" >/dev/null 2>&1
        exit 0
    fi
    sleep 0.3
done
