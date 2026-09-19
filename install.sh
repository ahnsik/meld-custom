#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PREFIX=${PREFIX:-"$HOME/.local"}
APP_DIR="$PREFIX/lib/meld-cutrom"
BIN_DIR="$PREFIX/bin"

for command_name in python3 glib-compile-resources glib-compile-schemas; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "install.sh: 필요한 명령을 찾을 수 없습니다: $command_name" >&2
        exit 1
    fi
done

if ! python3 -c \
        'import cairo, gi; gi.require_version("Gtk", "3.0"); gi.require_version("GtkSource", "4")' \
        >/dev/null 2>&1; then
    echo "install.sh: Meld_cutrom 실행에 필요한 Python GTK 패키지가 없습니다." >&2
    echo "Ubuntu에서는 다음 패키지를 설치하세요:" >&2
    echo "  sudo apt install python3-gi python3-gi-cairo gir1.2-gtk-3.0 gir1.2-gtksource-4" >&2
    exit 1
fi

install -d "$APP_DIR" "$BIN_DIR"
rm -rf -- "$APP_DIR/bin" "$APP_DIR/data" "$APP_DIR/meld"
cp -a "$SCRIPT_DIR/bin" "$SCRIPT_DIR/data" "$SCRIPT_DIR/meld" "$APP_DIR/"
install -m 644 "$SCRIPT_DIR/meld.doap" "$SCRIPT_DIR/COPYING" "$APP_DIR/"

glib-compile-resources \
    "$APP_DIR/meld/resources/meld.gresource.xml" \
    --sourcedir="$APP_DIR/meld/resources" \
    --sourcedir="$APP_DIR/data/icons/hicolor" \
    --target="$APP_DIR/data/org.gnome.MeldCu.gresource"
glib-compile-schemas "$APP_DIR/data"

chmod 755 "$APP_DIR/bin/meld"
ln -sfn "$APP_DIR/bin/meld" "$BIN_DIR/meld_cu"

echo "Meld_cutrom 설치가 완료되었습니다."
echo "실행 명령: meld_cu"
if ! command -v meld_cu >/dev/null 2>&1; then
    echo "$BIN_DIR 가 PATH에 포함되어 있지 않습니다." >&2
    echo "셸 설정 파일에 다음 줄을 추가하세요:" >&2
    echo "  export PATH=\"$BIN_DIR:\$PATH\"" >&2
fi
