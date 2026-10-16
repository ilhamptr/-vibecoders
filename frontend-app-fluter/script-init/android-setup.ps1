$ErrorActionPreference = "Stop"

$AvdName = if ($env:AVD_NAME) {
    $env:AVD_NAME
} else {
    "hackathon_api36"
}

$AndroidApi = if ($env:ANDROID_API) {
    $env:ANDROID_API
} else {
    "36"
}

function Get-AndroidSdkRoot {
    if ($env:ANDROID_SDK_ROOT) {
        return $env:ANDROID_SDK_ROOT
    }

    if ($env:ANDROID_HOME) {
        return $env:ANDROID_HOME
    }

    return "$env:LOCALAPPDATA\Android\Sdk"
}

function Find-SdkTool {
    param(
        [string]$SdkRoot,
        [string]$Tool
    )

    $latest = Join-Path $SdkRoot "cmdline-tools\latest\bin\$Tool"

    if (Test-Path $latest) {
        return $latest
    }

    $result = Get-ChildItem `
        -Path (Join-Path $SdkRoot "cmdline-tools") `
        -Filter $Tool `
        -Recurse `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if (-not $result) {
        throw "Could not find $Tool. Install Android SDK Command-Line Tools."
    }

    return $result.FullName
}

$SdkRoot = Get-AndroidSdkRoot

if (-not (Test-Path $SdkRoot)) {
    throw "Android SDK not found at $SdkRoot"
}

$SdkManager = Find-SdkTool $SdkRoot "sdkmanager.bat"
$AvdManager = Find-SdkTool $SdkRoot "avdmanager.bat"

if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
    $Abi = "arm64-v8a"
} else {
    $Abi = "x86_64"
}

$SystemImage = "system-images;android-$AndroidApi;google_apis;$Abi"

Write-Host "Android SDK:  $SdkRoot"
Write-Host "API:          $AndroidApi"
Write-Host "Architecture: $Abi"
Write-Host "AVD:          $AvdName"
Write-Host ""

Write-Host "Accepting SDK licenses..."

1..100 |
    ForEach-Object { "y" } |
    & $SdkManager --licenses

Write-Host "Installing Android components..."

& $SdkManager `
    "platform-tools" `
    "emulator" `
    "platforms;android-$AndroidApi" `
    $SystemImage

$Emulator = Join-Path $SdkRoot "emulator\emulator.exe"

$ExistingAvds = & $Emulator -list-avds

if ($ExistingAvds -contains $AvdName) {
    Write-Host "AVD '$AvdName' already exists."
} else {
    Write-Host "Creating AVD '$AvdName'..."

    "no" |
        & $AvdManager create avd `
            --name $AvdName `
            --package $SystemImage
}

Write-Host ""
Write-Host "Checking hardware acceleration..."

& $Emulator -accel-check

Write-Host ""
Write-Host "Android host setup complete."
Write-Host "Start with:"
Write-Host "  .\scripts\android-start.ps1"