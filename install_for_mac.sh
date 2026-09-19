#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SOURCE_APP="$SCRIPT_DIR/Meld_for_mac.app"
TARGET_APP="/Applications/Meld_for_mac.app"
OFFICIAL_APP="/Applications/Meld.app"

if [ "$(uname -m)" = "arm64" ] && [ -d /opt/homebrew/bin ]; then
    COMMAND_DIR="/opt/homebrew/bin"
else
    COMMAND_DIR="/usr/local/bin"
fi
COMMAND_PATH="$COMMAND_DIR/meld_for_mac"

if [ ! -x "$SOURCE_APP/Contents/MacOS/Meld" ]; then
    echo "install_for_mac: 먼저 ./build_meld_for_mac.sh 를 실행하세요." >&2
    exit 127
fi

if ! codesign --verify --deep --strict "$SOURCE_APP"; then
    echo "install_for_mac: Meld_for_mac.app 코드 서명이 유효하지 않습니다." >&2
    exit 1
fi

USE_SUDO=0
if [ ! -w /Applications ] || [ ! -w "$COMMAND_DIR" ]; then
    USE_SUDO=1
    if ! command -v sudo >/dev/null 2>&1; then
        echo "install_for_mac: 설치를 위해 관리자 권한이 필요합니다." >&2
        exit 1
    fi
fi

run_admin() {
    if [ "$USE_SUDO" -eq 1 ]; then
        sudo "$@"
    else
        "$@"
    fi
}

TEMP_APP="$TARGET_APP.installing.$$"
TEMP_LAUNCHER=$(mktemp "${TMPDIR:-/tmp}/meld_for_mac.XXXXXX")
trap 'rm -f "$TEMP_LAUNCHER"; run_admin rm -rf "$TEMP_APP"' EXIT HUP INT TERM

run_admin rm -rf "$TEMP_APP"
run_admin ditto "$SOURCE_APP" "$TEMP_APP"
codesign --verify --deep --strict "$TEMP_APP"

run_admin rm -rf "$TARGET_APP"
run_admin mv "$TEMP_APP" "$TARGET_APP"

cat >"$TEMP_LAUNCHER" <<'EOF'
#!/bin/sh

export PYTHONDONTWRITEBYTECODE=1
exec /Applications/Meld_for_mac.app/Contents/MacOS/Meld "$@"
EOF
run_admin install -m 755 "$TEMP_LAUNCHER" "$COMMAND_PATH"

if command -v brew >/dev/null 2>&1 &&
        brew list --cask meld >/dev/null 2>&1; then
    brew uninstall --cask meld
fi

if [ -e "$OFFICIAL_APP" ]; then
    run_admin rm -rf "$OFFICIAL_APP"
fi

for old_command in /opt/homebrew/bin/meld /usr/local/bin/meld; do
    if [ -L "$old_command" ]; then
        old_target=$(readlink "$old_command")
        case "$old_target" in
            *"/Caskroom/meld/"*|*"/Applications/Meld.app/"*)
                run_admin rm -f "$old_command"
                ;;
        esac
    fi
done

codesign --verify --deep --strict "$TARGET_APP"

if [ ! -x "$COMMAND_PATH" ]; then
    echo "install_for_mac: $COMMAND_PATH 설치에 실패했습니다." >&2
    exit 1
fi

echo "Installed $TARGET_APP"
echo "Installed command: $COMMAND_PATH"
echo "Run: meld_for_mac"
