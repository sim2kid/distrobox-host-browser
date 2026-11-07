# distrobox-host-browser

Open links from apps inside a Distrobox container in the **host's** default
browser (written for Bazzite + an Ubuntu container running Claude Desktop, with
Firefox as a Flatpak on the host).

## The problem

- A fresh container has no default web browser registered
  (`xdg-mime query default x-scheme-handler/https` prints nothing), so apps
  that check for one can fall back to an in-app browser or do nothing.
- Distrobox's own `xdg-open` shim runs the host `xdg-open` with an empty
  desktop environment (no `DISPLAY`, `WAYLAND_DISPLAY` or
  `XDG_CURRENT_DESKTOP`). The host `xdg-open` then tries `lynx`/`w3m`/etc. and
  fails with "no method available for opening".
- Flatpak Firefox also needs the display variables to start.

## What this installs (container only)

| Path | Purpose |
| --- | --- |
| `/usr/local/bin/host-open` | Runs `gio open` on the host with the display variables set |
| `/usr/local/bin/xdg-open` | Symlink to `host-open` (replaces Distrobox's shim) |
| `/usr/share/applications/host-browser.desktop` | A "Host Browser" desktop entry for http/https/html |
| `/etc/xdg/mimeapps.list` | Makes "Host Browser" the container's default for those types |
| `x-www-browser` alternative | For tools that call `x-www-browser` / `sensible-browser` |

Everything above is under `/usr` and `/etc` **inside the container**. The only
thing written to the shared home directory is
`~/.local/share/host-browser/raise-browser.sh`, which the host has to be able
to run (see below). The host's own `xdg-open` and default-browser settings are
untouched. (Do not put the wrapper in `~/.local/bin` or the defaults in
`~/.config/mimeapps.list`: the home directory is shared with the host and the
files would shadow the host's own.)

## Bringing the browser to the front

KDE's focus-stealing prevention leaves a window that was launched without an
activation token behind other windows. After opening an `http(s)` link,
`host-open` runs `share/raise-browser.sh` on the host, which asks KWin's
windows runner (`org.kde.KWin /WindowsRunner`) to activate the browser's
window. It waits up to ~9s so a cold-starting browser is raised once its window
exists. Needs `busctl` and `jq` on the host. Set `HOST_BROWSER_MATCH` (a
case-insensitive pattern, default `firefox`) if your browser is not Firefox.

## Install / uninstall

Run inside the container (needs `sudo`):

```sh
sh install.sh
sh uninstall.sh
```

`uninstall.sh` restores Distrobox's original `xdg-open` symlink and any
previous `/etc/xdg/mimeapps.list`.

After installing, fully quit and reopen apps so they re-check the default
browser.

## Check it works

```sh
xdg-mime query default x-scheme-handler/https   # host-browser.desktop
xdg-open https://example.com                    # opens in the host browser
```

## Notes

- `host-open` re-execs `/usr/bin/xdg-open` if it is run outside a container.
- Electron apps such as Claude Desktop appear to open links through the XDG
  desktop portal (`org.freedesktop.portal.OpenURI`) rather than `xdg-open`. In
  testing, Claude Desktop sent its links to the in-app browser, or nowhere,
  until the container had a registered default browser; after `install.sh`
  they opened in the host browser. The cause was inferred from the app's
  behavior, not confirmed in its source.
- If your session type is not KDE/Wayland, adjust the `:-` defaults in
  `bin/host-open`.

## AI disclosure

This project was written by Claude (Anthropic's AI model, via Claude Code).

## License

[MIT](LICENSE): use, copy, modify and redistribute freely.
