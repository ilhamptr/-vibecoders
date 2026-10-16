# Mobile Development Setup

This project uses:

- Docker for the Flutter development environment
- Android SDK Command-Line Tools on the host
- Android Emulator on the host
- ADB on the host
- VS Code Dev Containers for the development workspace

Flutter itself does **not** need to be installed on the host machine.

The Android Emulator stays on the host because it needs direct access to hardware virtualization and graphics acceleration.

---

# 1. Requirements

Install the following:

- Git
- Docker
- VS Code
- VS Code Dev Containers extension
- Android SDK Command-Line Tools

You do **not** need Android Studio.

---

# 2. Install Docker

## Windows / macOS

Install Docker Desktop.

Verify:

```bash
docker --version
docker compose version
```

## Linux

Install Docker Engine and Docker Compose using your distribution's recommended installation method.

Verify:

```bash
docker --version
docker compose version
```

Make sure your user can use Docker without `sudo` if desired.

---

# 3. Install Android SDK Command-Line Tools

Download the latest **Command line tools only** package from:

https://developer.android.com/studio#command-line-tools-only

Choose the package for your operating system.

The required SDK layout is important.

The final directory must contain:

```text
cmdline-tools/
└── latest/
    ├── bin/
    │   ├── sdkmanager
    │   └── avdmanager
    ├── lib/
    ├── NOTICE.txt
    └── source.properties
```

The scripts expect `sdkmanager` to exist under:

```text
$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/
```

---

# 4. Linux Setup

Create the Android SDK directory:

```bash
mkdir -p "$HOME/Android/Sdk/cmdline-tools/latest"
```

Extract the downloaded command-line tools.

The archive normally contains a directory named:

```text
cmdline-tools/
```

Move the **contents** of that directory into:

```text
$HOME/Android/Sdk/cmdline-tools/latest/
```

The result should look like:

```text
$HOME/Android/Sdk/
└── cmdline-tools/
    └── latest/
        ├── bin/
        ├── lib/
        ├── NOTICE.txt
        └── source.properties
```

Verify:

```bash
$HOME/Android/Sdk/cmdline-tools/latest/bin/sdkmanager --version
```

Add the following to your shell configuration.

For Bash:

```bash
nano ~/.bashrc
```

For Zsh:

```bash
nano ~/.zshrc
```

Add:

```bash
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"

export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH"
export PATH="$ANDROID_SDK_ROOT/platform-tools:$PATH"
export PATH="$ANDROID_SDK_ROOT/emulator:$PATH"
```

Reload your shell:

```bash
source ~/.bashrc
```

or:

```bash
source ~/.zshrc
```

Verify:

```bash
sdkmanager --version
```

---

# 5. Linux Hardware Virtualization

The Android Emulator should use KVM.

Check whether KVM exists:

```bash
ls -l /dev/kvm
```

You can also check emulator acceleration later with:

```bash
emulator -accel-check
```

If your user cannot access `/dev/kvm`, check your distribution's KVM configuration and group permissions.

A logout/login may be required after changing group membership.

---

# 6. macOS Setup

Create the SDK directory:

```bash
mkdir -p "$HOME/Library/Android/sdk/cmdline-tools/latest"
```

Extract the downloaded Android Command-Line Tools package.

Move the **contents** of the extracted `cmdline-tools` directory into:

```text
$HOME/Library/Android/sdk/cmdline-tools/latest/
```

The final structure should be:

```text
$HOME/Library/Android/sdk/
└── cmdline-tools/
    └── latest/
        ├── bin/
        ├── lib/
        ├── NOTICE.txt
        └── source.properties
```

Verify:

```bash
$HOME/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager --version
```

Add the following to:

```bash
~/.zshrc
```

```bash
export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"

export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH"
export PATH="$ANDROID_SDK_ROOT/platform-tools:$PATH"
export PATH="$ANDROID_SDK_ROOT/emulator:$PATH"
```

Reload:

```bash
source ~/.zshrc
```

Verify:

```bash
sdkmanager --version
```

---

# 7. Windows Setup

Create:

```text
C:\Android\Sdk
```

Then create:

```text
C:\Android\Sdk\cmdline-tools\latest
```

Extract the downloaded Android Command-Line Tools ZIP.

Move the **contents** of the extracted `cmdline-tools` directory into:

```text
C:\Android\Sdk\cmdline-tools\latest
```

The final structure should look like:

```text
C:\Android\Sdk\
└── cmdline-tools\
    └── latest\
        ├── bin\
        │   ├── sdkmanager.bat
        │   └── avdmanager.bat
        ├── lib\
        ├── NOTICE.txt
        └── source.properties
```

Do not accidentally create:

```text
cmdline-tools\latest\cmdline-tools\bin
```

The correct location is:

```text
cmdline-tools\latest\bin
```

---

# 8. Windows Environment Variables

Open:

```text
System Properties
→ Advanced
→ Environment Variables
```

Create:

```text
ANDROID_SDK_ROOT
```

with:

```text
C:\Android\Sdk
```

Add these entries to your user `Path`:

```text
%ANDROID_SDK_ROOT%\cmdline-tools\latest\bin
%ANDROID_SDK_ROOT%\platform-tools
%ANDROID_SDK_ROOT%\emulator
```

Open a new PowerShell window and verify:

```powershell
sdkmanager --version
```

---

# 9. Windows Hardware Virtualization

Hardware virtualization must be enabled in BIOS/UEFI.

Windows should also have the appropriate virtualization platform enabled for the Android Emulator.

After the emulator package has been installed, verify with:

```powershell
emulator -accel-check
```

---

# 10. Clone the Project

Clone the repository:

```bash
git clone <repository-url>
cd <repository-name>
```

---

# 11. Run the Android Setup Script

The setup script installs the Android components required by the project and creates the development emulator.

You only need to run this once per development machine.

## Linux / macOS

Make the scripts executable:

```bash
chmod +x script-init/android-setup.sh
chmod +x script-init/android-start.sh
```

Run:

```bash
./script-init/android-setup.sh
```

The script installs the required packages using `sdkmanager`, including:

```text
platform-tools
emulator
Android SDK platform
Android emulator system image
```

It also creates the project's AVD using `avdmanager`.

---

## Windows

Run:

```powershell
.\script-init\android-setup.ps1
```

The PowerShell setup script performs the same setup using the Windows Android SDK tools.

---

# 12. Verify the Android Installation

After setup, verify ADB:

```bash
adb version
```

Verify the emulator:

```bash
emulator -version
```

List configured Android Virtual Devices:

```bash
emulator -list-avds
```

The project development emulator should appear in the output.

---

# 13. Start the Development Emulator

The emulator and ADB server must be started on the host before Flutter inside Docker can use them.

## Linux / macOS

Run:

```bash
./script-init/android-start.sh
```

## Windows

Run:

```powershell
.\script-init\android-start.ps1
```

The startup script:

1. starts the host ADB server;
2. makes ADB available to the Docker development container;
3. starts the Android Emulator if it is not already running;
4. waits until Android has completed booting.

When ready, you should see something similar to:

```text
Android emulator ready.
Device: emulator-5554
```

Verify:

```bash
adb devices
```

Expected output:

```text
List of devices attached
emulator-5554    device
```

---

# 14. Start the Development Container

On **native Linux Docker Engine**, first run this from the repository root on
**the host**:

```bash
bash script-init/configure-adb-host.sh
```

The helper starts a temporary container on the Flutter Compose network, discovers
its IPv4 default gateway, and saves `ADB_HOST` in the local, gitignored `.env`.
Other `.env` settings are preserved. Run it again if the Compose network is
recreated (for example, after `docker compose down`) or its subnet changes.
It requires Docker access and may pull the Flutter image on first use.

On **macOS / Windows with Docker Desktop**, no override is normally needed:
`host.docker.internal` remains the default. Docker Desktop's internal bridge
gateway is inside its VM, so do not substitute that gateway for the host name.

For a manual override, put `ADB_HOST=<reachable-host-address>` in `.env` beside
`docker-compose.yml`. For the reported Linux network, `ADB_HOST=172.18.0.1` is a
valid immediate workaround; the helper avoids recording a fixed subnet in the
shared configuration. Shell exports of `ADB_HOST` take precedence over `.env`.
Rootless Docker and remote Docker daemons may need a manual reachable address;
the native bridge gateway method assumes the emulator runs on the Docker host.

If the Dev Container already exists, use **Dev Containers: Rebuild Container**
after changing `.env`. A plain restart does not update its environment. For a
terminal-only workflow, use `docker compose up -d --force-recreate flutter`.

Open the repository in VS Code.

Open the Command Palette:

```text
Ctrl + Shift + P
```

or on macOS:

```text
Cmd + Shift + P
```

Select:

```text
Dev Containers: Reopen in Container
```

VS Code will start the configured Docker development environment.

---

# 15. Verify the Emulator From the Dev Container

Run these commands **inside the Dev Container**, in order:

```bash
printf '%s\n' "$ADB_SERVER_SOCKET"
# Expected: tcp:<reachable-host-address>:5037

# Bound the TCP check so a firewall drop does not hang the terminal.
adb_host="${ADB_SERVER_SOCKET#tcp:}"
adb_host="${adb_host%:5037}"
timeout 3 bash -c 'exec 3<>/dev/tcp/$1/5037' _ "$adb_host"

adb devices -l
flutter devices
cd /flutter/framework
flutter run -d emulator-5554
```

The TCP check must exit with status 0. `adb devices -l` should list
`emulator-5554` with status `device`; use the actual serial if yours differs.
`flutter devices` must list the same Android device. Finally, verify that the
app opens and Flutter attaches successfully, including hot reload (`r`). Device
discovery alone does not verify the debug connection; see the forwarding note
below if launch succeeds but attachment fails.

---

# Normal Development Workflow

After the one-time setup, developers normally only need to do the following.

## Linux / macOS

Start Android:

```bash
./script-init/android-start.sh
```

Then open the repository using:

```text
Dev Containers: Reopen in Container
```

Verify:

```bash
flutter devices
```

---

## Windows

Start Android:

```powershell
.\script-init\android-start.ps1
```

Then open the repository using:

```text
Dev Containers: Reopen in Container
```

Verify:

```bash
flutter devices
```

---

# Stop the Android Emulator

Run this on the **Linux/macOS host**, from the repository root. The same script
works with POSIX `sh` and Bash:

```bash
sh script-init/android-stop.sh
# Or:
bash script-init/android-stop.sh
```

With one running emulator, it requests shutdown of that emulator. With several,
choose its AVD name (the identifier shown by `emulator -list-avds`) or ADB serial:

```bash
sh script-init/android-stop.sh --avd Pixel_9_API_36
bash script-init/android-stop.sh --serial emulator-5554
```

`AVD_NAME` can also select the target, matching the startup script's configuration:

```bash
AVD_NAME=hackathon_api36 sh script-init/android-stop.sh
```

This works for AVDs created or launched through Android Studio as well as the
project scripts. It finds ADB through `ANDROID_SDK_ROOT`, `ANDROID_HOME`, `PATH`,
or the standard Android Studio SDK directory (`~/Android/Sdk` on Linux and
`~/Library/Android/sdk` on macOS). For a custom installation, set `ANDROID_HOME`
to Android Studio's Android SDK location.

The script sends [`adb -s SERIAL emu kill`](https://developer.android.com/studio/run/emulator-console)
to the selected emulator. It preserves the AVD and its data, ignores physical
devices, and leaves the host ADB server running. It explicitly queries the host's
local ADB server on port 5037, even if `ADB_SERVER_SOCKET` is exported in the
shell. No running emulators exits successfully. The shutdown request returns
before the emulator fully closes.

Mock-based checks for both shells (no emulator is stopped):

```bash
python3 -m unittest discover -s script-init/tests -v
```

---

# Troubleshooting

## `sdkmanager` is not found

Check:

```bash
echo $ANDROID_SDK_ROOT
```

Linux should normally resolve to:

```text
~/Android/Sdk
```

macOS should normally resolve to:

```text
~/Library/Android/sdk
```

On Windows:

```powershell
$env:ANDROID_SDK_ROOT
```

Then verify that this exists:

```text
cmdline-tools/latest/bin/sdkmanager
```

or on Windows:

```text
cmdline-tools\latest\bin\sdkmanager.bat
```

---

## `adb` is not found

Run the setup script first.

It installs:

```text
platform-tools
```

which contains ADB.

Then verify:

```bash
adb version
```

---

## `emulator` is not found

Run the setup script.

Then verify:

```bash
emulator -version
```

The emulator executable should exist under:

```text
$ANDROID_SDK_ROOT/emulator/
```

---

## No Android emulator exists

Check:

```bash
emulator -list-avds
```

If the project's emulator is missing, rerun the setup script:

Linux/macOS:

```bash
./script-init/android-setup.sh
```

Windows:

```powershell
.\script-init\android-setup.ps1
```

---

## Emulator is extremely slow

Check hardware acceleration:

```bash
emulator -accel-check
```

If acceleration is unavailable, verify that virtualization is enabled in BIOS/UEFI and that the operating system's virtualization support is configured correctly.

---

## Emulator works on the host but not inside Docker

A timeout to port **5037** is a host network connectivity problem when the ADB
binary itself runs. Reinstalling the container SDK will not fix that timeout.

Docker's `host-gateway` normally resolves to the **default bridge** address,
not the active Compose bridge. Therefore `host.docker.internal -> 172.17.0.1`
with a Compose gateway of `172.18.0.1` is expected. Both can be host addresses;
the difference alone does not prove why one times out. If only the Compose
gateway is reachable, use the Linux helper above and inspect host routing and
firewall rules if needed. See [Docker's host-gateway documentation](https://docs.docker.com/reference/cli/dockerd/#configure-host-gateway-ip).
Docker Desktop instead provides a [special host DNS name](https://docs.docker.com/desktop/features/networking/networking-how-tos/#i-want-to-connect-from-a-container-to-a-service-on-the-host).

On the **host**, confirm the emulator and listener:

```bash
adb devices -l
# Linux:
ss -ltnp 'sport = :5037'
```

ADB must listen on an address reachable from Docker, not only host loopback.
The existing `script-init/android-start.sh` / `.ps1` starts it using
`adb -a -P 5037 nodaemon server`. If starting it manually, first stop the old
host server with `adb kill-server`, then run that command in a dedicated host
terminal. Keep access to this server limited to the development network in the
host firewall; clients reaching it can control attached devices.

Then repeat section 15 in the container. A TCP timeout indicates routing or
firewall filtering; connection refused usually means no listener on that
address. If TCP succeeds but ADB fails, compare `adb version` on both sides and
align the platform-tools versions before restarting the **host** server. If ADB
responds with an empty device list, check the host emulator rather than Docker
DNS. An `offline` device must be brought online on the host.

Port 5037 is the **ADB server** protocol port. Do not run `adb connect
host.docker.internal:5037`: `adb connect` connects to a device's adbd, not to an
ADB server. No Compose `ports:` mapping is needed for container-to-host access.

## Flutter launches the app but cannot attach or hot reload

With a remote ADB server, `adb forward` creates the forwarded TCP listener on
**the host**. Flutter can still attempt to connect to container `127.0.0.1` at
that port. Changing `ADB_SERVER_SOCKET` fixes ADB discovery but does not bridge
those two loopback interfaces. Flutter's [service discovery implementation](https://github.com/flutter/flutter/blob/master/packages/flutter_tools/lib/src/protocol_discovery.dart)
replaces the forwarded port in the service URI.

If `flutter run -v` shows this failure, use a fixed VM-service port and a TCP
relay. With `socat` installed in the container, run in one container terminal:

```bash
adb_host="${ADB_SERVER_SOCKET#tcp:}"
adb_host="${adb_host%:5037}"
socat TCP4-LISTEN:8181,bind=127.0.0.1,reuseaddr,fork "TCP:${adb_host}:8181"
```

In another container terminal:

```bash
cd /flutter/framework
flutter run -d emulator-5554 --host-vmservice-port=8181
```

The host ADB server must accept connections to its forwarded port (start it
with `-a`, and allow TCP 8181 from the container network in the host firewall).
Check `adb forward --list` and the host's listener while Flutter is running.
This relay is only needed for the debug service; port 5037 remains configured
through `ADB_SERVER_SOCKET`. Stop the relay with Ctrl+C after debugging.

---

# Important

Do not install the Android Emulator inside the Docker container.

The intended setup is:

- Android SDK Command-Line Tools: host
- Android Emulator: host
- ADB server: host
- Flutter development environment: Docker / Dev Container

This keeps the development environment reproducible while allowing the emulator to use native host virtualization.