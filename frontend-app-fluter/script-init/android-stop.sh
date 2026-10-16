#!/bin/sh

# Run on the Linux/macOS host. Compatible with POSIX sh and Bash.
set -eu

usage() {
    cat <<'EOF'
Usage: android-stop.sh [--avd NAME | --serial emulator-PORT]

Stop a running Android Emulator, including Android Studio AVDs.
With no arguments, use AVD_NAME if set; otherwise stop the sole emulator.
When multiple emulators are running, choose one explicitly.

Examples (run on the host):
  sh script-init/android-stop.sh
  bash script-init/android-stop.sh --avd Pixel_9_API_36
  sh script-init/android-stop.sh --serial emulator-5554

SDK lookup: ANDROID_SDK_ROOT, ANDROID_HOME, adb on PATH, then the
standard Linux/macOS Android Studio SDK directory.
The script uses the local ADB server on port 5037 and leaves it running.
EOF
}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

TARGET_NAME=${AVD_NAME:-}
TARGET_SERIAL=
case $# in
    0) ;;
    1)
        case "$1" in
            -h|--help) usage; exit 0 ;;
            *) usage >&2; exit 2 ;;
        esac
        ;;
    2)
        [ -n "$2" ] || fail 'The emulator name or serial must not be empty.'
        case "$1" in
            --avd) TARGET_NAME=$2 ;;
            --serial)
                TARGET_NAME=
                TARGET_SERIAL=$2
                case "$TARGET_SERIAL" in
                    emulator-*)
                        case "${TARGET_SERIAL#emulator-}" in
                            ''|*[!0-9]*) fail 'Expected a serial such as emulator-5554.' ;;
                        esac
                        ;;
                    *) fail 'Only emulator serials such as emulator-5554 are supported.' ;;
                esac
                ;;
            *) usage >&2; exit 2 ;;
        esac
        ;;
    *) usage >&2; exit 2 ;;
esac

find_adb() {
    for sdk_path in "${ANDROID_SDK_ROOT:-}" "${ANDROID_HOME:-}"; do
        if [ -n "$sdk_path" ] && [ -x "$sdk_path/platform-tools/adb" ]; then
            printf '%s\n' "$sdk_path/platform-tools/adb"
            return
        fi
    done

    if command -v adb >/dev/null 2>&1; then
        command -v adb
        return
    fi

    case "$(uname -s)" in
        Linux) sdk_path="$HOME/Android/Sdk" ;;
        Darwin) sdk_path="$HOME/Library/Android/sdk" ;;
        *) return 1 ;;
    esac
    [ -x "$sdk_path/platform-tools/adb" ] || return 1
    printf '%s\n' "$sdk_path/platform-tools/adb"
}

ADB=$(find_adb) || fail 'ADB not found. Set ANDROID_HOME to the SDK location shown in Android Studio, or add platform-tools to PATH.'

host_adb() {
    # Explicit host/port override any container ADB_SERVER_SOCKET settings.
    "$ADB" -H 127.0.0.1 -P 5037 "$@"
}

console_command() {
    # adb emu connects directly to the local emulator console. Some console
    # failures return exit status zero, so also check its KO: response.
    if console_output=$(host_adb "$@" 2>&1); then
        printf '%s\n' "$console_output" | tr -d '\r' |
            awk '{ print; if ($0 ~ /^KO:/) failed = 1 } END { exit failed }'
    else
        printf '%s\n' "$console_output" >&2
        return 1
    fi
}

avd_name() {
    avd_output=$(console_command -s "$1" emu avd name 2>/dev/null) || return 1
    printf '%s\n' "$avd_output" |
        awk 'NF && $0 != "OK" { print; found = 1; exit } END { if (!found) exit 1 }'
}

DEVICES=$(host_adb devices) || fail 'Cannot query the local host ADB server.'
# Include offline emulators: their console may still accept emu kill.
SERIALS=$(printf '%s\n' "$DEVICES" | awk '$1 ~ /^emulator-[0-9]+$/ { print $1 }')
if [ -z "$SERIALS" ]; then
    echo 'No running Android emulators found.'
    exit 0
fi

MATCH_COUNT=0
SELECTED_SERIAL=
for serial in $SERIALS; do
    if [ -n "$TARGET_SERIAL" ]; then
        [ "$serial" = "$TARGET_SERIAL" ] || continue
    elif [ -n "$TARGET_NAME" ]; then
        name=$(avd_name "$serial") || continue
        [ "$name" = "$TARGET_NAME" ] || continue
    fi
    MATCH_COUNT=$((MATCH_COUNT + 1))
    SELECTED_SERIAL=$serial
done

if [ "$MATCH_COUNT" -ne 1 ]; then
    if [ "$MATCH_COUNT" -eq 0 ]; then
        printf 'No running emulator matches: %s\n' "${TARGET_SERIAL:-$TARGET_NAME}" >&2
    else
        echo 'Multiple emulators match. Select one with --avd NAME or --serial emulator-PORT.' >&2
    fi
    echo 'Available emulators:' >&2
    for serial in $SERIALS; do
        name=$(avd_name "$serial") || name='AVD name unavailable'
        printf '  %s  %s\n' "$serial" "$name" >&2
    done
    exit 1
fi

printf 'Requesting shutdown of %s...\n' "$SELECTED_SERIAL"
console_command -s "$SELECTED_SERIAL" emu kill || fail "Could not stop $SELECTED_SERIAL."
printf 'Shutdown requested for %s. The emulator may take a few seconds to close.\n' "$SELECTED_SERIAL"
