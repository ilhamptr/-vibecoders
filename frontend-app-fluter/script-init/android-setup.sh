#!/usr/bin/env bash

if ! command -v java >/dev/null 2>&1; then
    echo "ERROR: Java is not installed."
    echo "Install OpenJDK according to README.md."
    exit 1
fi

if [[ -z "${JAVA_HOME:-}" ]]; then
    echo "ERROR: JAVA_HOME is not configured."
    echo "See the OpenJDK setup section in README.md."
    exit 1
fi
set -euo pipefail

AVD_NAME="${AVD_NAME:-hackathon_api36}"
ANDROID_API="${ANDROID_API:-36}"

detect_sdk_root() {
    if [[ -n "${ANDROID_SDK_ROOT:-}" && -d "$ANDROID_SDK_ROOT" ]]; then
        echo "$ANDROID_SDK_ROOT"
        return
    fi

    if [[ -n "${ANDROID_HOME:-}" && -d "$ANDROID_HOME" ]]; then
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

find_sdk_tool() {
    local tool="$1"

    if [[ -x "$SDK_ROOT/cmdline-tools/latest/bin/$tool" ]]; then
        echo "$SDK_ROOT/cmdline-tools/latest/bin/$tool"
        return
    fi

    for candidate in "$SDK_ROOT"/cmdline-tools/*/bin/"$tool"; do
        if [[ -x "$candidate" ]]; then
            echo "$candidate"
            return
        fi
    done

    echo "Cannot find $tool in $SDK_ROOT/cmdline-tools." >&2
    echo "Install Android SDK Command-Line Tools first." >&2
    exit 1
}

SDK_ROOT="$(detect_sdk_root)"

if [[ ! -d "$SDK_ROOT" ]]; then
    echo "Android SDK not found at:"
    echo "  $SDK_ROOT"
    echo
    echo "Install Android Studio / Android SDK Command-Line Tools first."
    exit 1
fi

SDKMANAGER="$(find_sdk_tool sdkmanager)"
AVDMANAGER="$(find_sdk_tool avdmanager)"

case "$(uname -m)" in
    arm64|aarch64)
        ABI="arm64-v8a"
        ;;
    x86_64|amd64)
        ABI="x86_64"
        ;;
    *)
        echo "Unsupported CPU architecture: $(uname -m)"
        exit 1
        ;;
esac

SYSTEM_IMAGE="system-images;android-${ANDROID_API};google_apis;${ABI}"

echo "Android SDK:   $SDK_ROOT"
echo "API:           $ANDROID_API"
echo "Architecture:  $ABI"
echo "AVD:           $AVD_NAME"
echo

echo "Accepting Android SDK licenses..."
yes | "$SDKMANAGER" --licenses >/dev/null || true

echo "Installing host emulator components..."

"$SDKMANAGER" \
    "platform-tools" \
    "emulator" \
    "platforms;android-${ANDROID_API}" \
    "$SYSTEM_IMAGE"

EMULATOR="$SDK_ROOT/emulator/emulator"

if "$EMULATOR" -list-avds | grep -Fxq "$AVD_NAME"; then
    echo "AVD '$AVD_NAME' already exists."
else
    echo "Creating AVD '$AVD_NAME'..."

    printf 'no\n' | "$AVDMANAGER" create avd \
        --name "$AVD_NAME" \
        --package "$SYSTEM_IMAGE"
fi

echo
echo "Checking hardware acceleration..."
"$EMULATOR" -accel-check || true

echo
echo "Android host setup complete."
echo "Start it with:"
echo "  ./scripts/android-start.sh"