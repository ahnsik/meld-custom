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

The launcher uses the locally built `Meld_for_mac.app` bundle.
