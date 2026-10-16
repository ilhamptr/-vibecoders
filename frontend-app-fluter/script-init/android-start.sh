#!/usr/bin/env bash

set -euo pipefail

AVD_NAME="${AVD_NAME:-hackathon_api36}"

detect_sdk_root() {
    if [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then
        echo "$ANDROID_SDK_ROOT"
        return
    fi

    if [[ -n "${ANDROID_HOME:-}" ]]; then
        echo "$ANDROID_HOME"
        return
    fi

    case "$(uname -s)" in
        Darwin)
            echo "$HOME/Library/Android/sdk"
            ;;
        Linux)
            echo "$HOME/Android/Sdk"
            ;;
        *)
            echo "Unsupported OS." >&2
            exit 1
            ;;
    esac
}

SDK_ROOT="$(detect_sdk_root)"

ADB="$SDK_ROOT/platform-tools/adb"
EMULATOR="$SDK_ROOT/emulator/emulator"

if [[ ! -x "$ADB" ]]; then
    echo "ADB not found: $ADB"
    echo "Run ./scripts/android-setup.sh first."
    exit 1
fi

if [[ ! -x "$EMULATOR" ]]; then
    echo "Emulator not found: $EMULATOR"
    echo "Run ./scripts/android-setup.sh first."
    exit 1
fi

mkdir -p "$HOME/.android"

echo "Restarting ADB server for Docker access..."

"$ADB" kill-server >/dev/null 2>&1 || true

nohup "$ADB" \
    -a \
    -P 5037 \
    nodaemon server \
    > "$HOME/.android/hackathon-adb.log" \
    2>&1 &

sleep 1

echo "ADB server listening on port 5037."

SERIAL="$(
    "$ADB" devices |
    awk '/^emulator-[0-9]+[[:space:]]+device$/ { print $1; exit }'
)"

if [[ -z "$SERIAL" ]]; then
    echo "Starting emulator '$AVD_NAME'..."

    nohup "$EMULATOR" \
        -avd "$AVD_NAME" \
        -gpu auto \
        > "$HOME/.android/hackathon-emulator.log" \
        2>&1 &

    echo "Waiting for emulator..."

    while [[ -z "$SERIAL" ]]; do
        sleep 2

        SERIAL="$(
            "$ADB" devices |
            awk '/^emulator-[0-9]+[[:space:]]+device$/ { print $1; exit }'
        )"
    done
else
    echo "Emulator already running: $SERIAL"
fi

echo "Waiting for Android to finish booting..."

while true; do
    BOOT="$(
        "$ADB" -s "$SERIAL" shell getprop sys.boot_completed \
        2>/dev/null |
        tr -d '\r'
    )"

    if [[ "$BOOT" == "1" ]]; then
        break
    fi

    sleep 2
done

echo
echo "Android emulator ready."
echo "Device: $SERIAL"
echo
"$ADB" devices