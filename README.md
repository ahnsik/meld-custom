# Meld for macOS

The `for_mac` branch contains a macOS customization based on Meld 3.22.2.

Build the application bundle:

```sh
brew install --cask meld
brew install meson ninja glib gtk+3 gtksourceview4 pygobject3 itstool
./build_meld_for_mac.sh
```

Run the customized build:

```sh
./meld_for_mac
```

The launcher uses the locally built `Meld_for_mac.app` bundle. On macOS, the
application uses left-aligned traffic-light window controls and macOS-specific
styling for title bars, tabs, buttons, selectors, and menus.

Install the customized application for all terminal sessions and remove the
official Homebrew Meld installation:

```sh
./install_for_mac.sh
meld_for_mac
```

The installer copies the application to `/Applications/Meld_for_mac.app` and
installs the `meld_for_mac` command in `/opt/homebrew/bin` on Apple Silicon or
`/usr/local/bin` on Intel Macs.
