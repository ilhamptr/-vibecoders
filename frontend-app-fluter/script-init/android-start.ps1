$ErrorActionPreference = "Stop"

$AvdName = if ($env:AVD_NAME) {
    $env:AVD_NAME
} else {
    "hackathon_api36"
}

if ($env:ANDROID_SDK_ROOT) {
    $SdkRoot = $env:ANDROID_SDK_ROOT
}
elseif ($env:ANDROID_HOME) {
    $SdkRoot = $env:ANDROID_HOME
}
else {
    $SdkRoot = "$env:LOCALAPPDATA\Android\Sdk"
}

$Adb = Join-Path $SdkRoot "platform-tools\adb.exe"
$Emulator = Join-Path $SdkRoot "emulator\emulator.exe"

if (-not (Test-Path $Adb)) {
    throw "ADB not found. Run android-setup.ps1 first."
}

if (-not (Test-Path $Emulator)) {
    throw "Android Emulator not found. Run android-setup.ps1 first."
}

$AndroidDir = Join-Path $HOME ".android"

New-Item `
    -ItemType Directory `
    -Force `
    -Path $AndroidDir |
    Out-Null

Write-Host "Restarting ADB server for Docker access..."

& $Adb kill-server 2>$null

Start-Process `
    -FilePath $Adb `
    -ArgumentList "-a", "-P", "5037", "nodaemon", "server" `
    -WindowStyle Hidden `
    -RedirectStandardOutput "$AndroidDir\hackathon-adb.log" `
    -RedirectStandardError "$AndroidDir\hackathon-adb-error.log"

Start-Sleep -Seconds 1

function Get-EmulatorSerial {
    $Devices = & $Adb devices

    foreach ($Line in $Devices) {
        if ($Line -match "^(emulator-\d+)\s+device$") {
            return $Matches[1]
        }
    }

    return $null
}

$Serial = Get-EmulatorSerial

if (-not $Serial) {
    Write-Host "Starting emulator '$AvdName'..."

    Start-Process `
        -FilePath $Emulator `
        -ArgumentList "-avd", $AvdName, "-gpu", "auto"

    Write-Host "Waiting for emulator..."

    while (-not $Serial) {
        Start-Sleep -Seconds 2
        $Serial = Get-EmulatorSerial
    }
}
else {
    Write-Host "Emulator already running: $Serial"
}

Write-Host "Waiting for Android to finish booting..."

do {
    Start-Sleep -Seconds 2

    $BootCompleted = (
        & $Adb `
            -s $Serial `
            shell getprop sys.boot_completed
    ).Trim()

} while ($BootCompleted -ne "1")

Write-Host ""
Write-Host "Android emulator ready."
Write-Host "Device: $Serial"
Write-Host ""

& $Adb devices