#!/usr/bin/env bash

set -euo pipefail

AVD_NAME="${AVD_NAME:-hackathon_api36}"

case "$(uname -s)" in
    Linux)
        DEFAULT_SDK_ROOT="$HOME/Android/Sdk"
        ;;
    Darwin)
        DEFAULT_SDK_ROOT="$HOME/Library/Android/sdk"
        ;;
    *)
        echo "ERROR: This cleanup script supports Linux and macOS only."
        exit 1
        ;;
esac

SDK_ROOT="${ANDROID_HOME:-$DEFAULT_SDK_ROOT}"

echo "Android development environment cleanup"
echo
echo "This will remove:"
echo "  SDK:          $SDK_ROOT"
echo "  AVD:          $AVD_NAME"
echo "  shell exports created by this project"
echo "  project Android logs"
echo
echo "Java, Docker and VS Code will NOT be removed."
echo

read -r -p "Continue? [y/N] " ANSWER

case "$ANSWER" in
    y|Y|yes|YES)
        ;;
    *)
        echo "Cleanup cancelled."
        exit 0
        ;;
esac


# ------------------------------------------------------------
# Stop ADB
# ------------------------------------------------------------

ADB="$SDK_ROOT/platform-tools/adb"

if [[ -x "$ADB" ]]; then
    echo "Stopping ADB server..."
    "$ADB" kill-server >/dev/null 2>&1 || true
fi


# ------------------------------------------------------------
# Stop running project emulator
# ------------------------------------------------------------

if [[ -x "$ADB" ]]; then
    while read -r SERIAL; do
        [[ -z "$SERIAL" ]] && continue

        AVD="$(
            "$ADB" -s "$SERIAL" emu avd name \
                2>/dev/null |
                head -n 1 |
                tr -d '\r'
        )"

        if [[ "$AVD" == "$AVD_NAME" ]]; then
            echo "Stopping emulator: $SERIAL"
            "$ADB" -s "$SERIAL" emu kill >/dev/null 2>&1 || true
        fi
    done < <(
        "$ADB" devices |
        awk '/^emulator-[0-9]+[[:space:]]+device$/ {
            print $1
        }'
    )
fi


# ------------------------------------------------------------
# Remove AVD
# ------------------------------------------------------------

AVD_DIR="$HOME/.android/avd/${AVD_NAME}.avd"
AVD_INI="$HOME/.android/avd/${AVD_NAME}.ini"

if [[ -d "$AVD_DIR" ]]; then
    echo "Removing AVD directory:"
    echo "  $AVD_DIR"

    rm -rf "$AVD_DIR"
fi

if [[ -f "$AVD_INI" ]]; then
    echo "Removing AVD configuration:"
    echo "  $AVD_INI"

    rm -f "$AVD_INI"
fi


# ------------------------------------------------------------
# Remove logs created by android-start.sh
# ------------------------------------------------------------

rm -f "$HOME/.android/hackathon-adb.log"
rm -f "$HOME/.android/hackathon-emulator.log"


# ------------------------------------------------------------
# Remove environment block from shell configuration
# ------------------------------------------------------------

remove_shell_block() {
    local FILE="$1"

    if [[ ! -f "$FILE" ]]; then
        return
    fi

    if ! grep -q \
        '# >>> hackathon-mobile android >>>' \
        "$FILE"; then
        return
    fi

    echo "Removing Android environment from:"
    echo "  $FILE"

    awk '
        /^# >>> hackathon-mobile android >>>$/ {
            removing = 1
            next
        }

        /^# <<< hackathon-mobile android <<</ {
            removing = 0
            next
        }

        !removing {
            print
        }
    ' "$FILE" > "${FILE}.tmp"

    mv "${FILE}.tmp" "$FILE"
}

remove_shell_block "$HOME/.bashrc"
remove_shell_block "$HOME/.zshrc"
remove_shell_block "$HOME/.bash_profile"
remove_shell_block "$HOME/.profile"


# ------------------------------------------------------------
# Delete Android SDK
# ------------------------------------------------------------

if [[ -d "$SDK_ROOT" ]]; then
    echo
    echo "Deleting Android SDK:"
    echo "  $SDK_ROOT"

    rm -rf "$SDK_ROOT"
fi


# ------------------------------------------------------------
# Remove empty project-created Android directories
# ------------------------------------------------------------

if [[ -d "$HOME/.android/avd" ]]; then
    rmdir "$HOME/.android/avd" 2>/dev/null || true
fi

if [[ -d "$HOME/.android" ]]; then
    rmdir "$HOME/.android" 2>/dev/null || true
fi


echo
echo "Android development environment removed."
echo
echo "Open a new terminal before continuing."