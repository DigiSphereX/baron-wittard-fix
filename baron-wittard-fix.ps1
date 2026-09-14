param(
    [switch]$Force,          # force re-install of the DX Studio Player even if it is detected
    [switch]$SkipInstall,    # never download/install the engine, only check and launch the game
    [switch]$NoLaunch,       # do not start the game afterwards (useful for testing)
    [switch]$Uninstall,      # remove the installed DX Studio Player engine, then exit
    [string]$SetupPath = ''  # use this exact setup file instead of the bundled/downloaded one
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$gameDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -LiteralPath $gameDir

# ---------------------------------------------------------------------------
# Known-good build of the DX Studio Player runtime (the game's rendering engine)
#   source : official file hosted on the Internet Archive (dxstudio.com is dead)
#   build  : v3.2.77 (Worldweaver Ltd.)
# ---------------------------------------------------------------------------
$setupUrl      = 'https://web.archive.org/web/20130614082456id_/http://www.dxstudio.com/downloads/dxstudioplayersetup.exe'
$setupFileName = 'DXStudioPlayerSetup.exe'
$setupSha256   = '3ADBFA760D46B2C2086F920DE94A112CD8A2F0D21ECA600D524CE57391E14D33'
$setupMinSize  = 20000000                                      # ~20 MB

$playerDir     = 'C:\Program Files\Worldweaver\DX Studio Player'

Write-Host ""
Write-Host "=============================================================="
Write-Host "  Baron Wittard: Nemesis of Ragnarok - Fix & Launcher"
Write-Host "  Repairs the missing DX Studio Player engine then starts"
Write-Host "  the game (fixes the dxstudio.com '502' download error)."
Write-Host "=============================================================="
Write-Host "Game directory : $gameDir"
Write-Host "Engine required: DX Studio Player v3.2.77 (Worldweaver Ltd.)"
Write-Host ""

# ---------------------------------------------------------------------------
# Helper: is the DX Studio Player runtime already installed?
# ---------------------------------------------------------------------------
function Test-DXStudioPlayerInstalled {
    if (Test-Path -LiteralPath $playerDir) { return $true }
    $keys = @(
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($k in $keys) {
        $found = Get-ItemProperty -Path $k -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -match 'DX Studio Player' }
        if ($found) { return $true }
    }
    return $false
}

# ---------------------------------------------------------------------------
# Helper: install the (already verified) setup silently, elevated
# ---------------------------------------------------------------------------
function Install-DXStudioPlayer {
    param([string]$SetupPath)

    Write-Host "      Installing... (a UAC prompt may appear - please click Yes)"
    $proc = $null
    try {
        $proc = Start-Process -FilePath $SetupPath -ArgumentList @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART') -Verb RunAs -Wait -PassThru
    }
    catch {
        Write-Warning "Elevation / install failed: $($_.Exception.Message)"
        Write-Warning "Run the fixer again and accept the UAC prompt."
        return $false
    }

    if (-not $proc -or $proc.ExitCode -ne 0) {
        Write-Warning "The setup exited with code $(if ($proc) { $proc.ExitCode } else { 'unknown' })."
        return $false
    }
    return $true
}

# ---------------------------------------------------------------------------
# Helper: uninstall the DX Studio Player engine (silent Inno uninstaller first,
# then remove leftovers: folder, registry entries and the cached setup).
# ---------------------------------------------------------------------------
function Remove-DXStudioPlayer {
    $found = $false

    $uninstPaths = @(
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    )
    foreach ($base in $uninstPaths) {
        Get-ChildItem -Path $base -ErrorAction SilentlyContinue | ForEach-Object {
            $prop = Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue
            if ($prop.DisplayName -match 'DX Studio Player') {
                $found = $true
                Write-Host "  Found installation: $($prop.DisplayName) $(if ($prop.DisplayVersion) { $prop.DisplayVersion })"
                $un = $prop.UninstallString
                if ($un -match '([A-Za-z]:\\[^"\\]*(?:\\[^"\\]*)*\.exe)') {
                    $unExe = $matches[1]
                    Write-Host "  Running uninstaller: $unExe"
                    try {
                        Start-Process -FilePath $unExe -ArgumentList @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART') -Verb RunAs -Wait -ErrorAction Stop | Out-Null
                    }
                    catch {
                        Write-Warning "  Uninstaller failed: $($_.Exception.Message)"
                    }
                }
                Remove-Item -Path $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    if (Test-Path -LiteralPath $playerDir) {
        Write-Host "  Removing leftover folder: $playerDir"
        foreach ($i in 1..3) {
            Remove-Item -LiteralPath $playerDir -Recurse -Force -ErrorAction SilentlyContinue
            if (-not (Test-Path -LiteralPath $playerDir)) { break }
            Start-Sleep -Seconds 2
        }
        if (Test-Path -LiteralPath $playerDir) {
            Write-Warning "  Some files in $playerDir are still in use and could not be deleted now."
            Write-Warning "  A reboot usually allows Windows to finish the cleanup."
            $found = $true
        }
    }
    foreach ($k in @('HKLM:\SOFTWARE\WOW6432Node\Worldweaver', 'HKLM:\SOFTWARE\Worldweaver', 'HKCU:\SOFTWARE\Worldweaver')) {
        Remove-Item -LiteralPath $k -Recurse -Force -ErrorAction SilentlyContinue
    }

    $cacheDir = Join-Path $env:TEMP 'baron-wittard-fix'
    if (Test-Path -LiteralPath $cacheDir) {
        Write-Host "  Removing cached download: $cacheDir"
        Remove-Item -LiteralPath $cacheDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    if ($found) { Write-Host "  DX Studio Player removed." }
    else        { Write-Host "  DX Studio Player was not found - nothing to remove." }
}

# ---------------------------------------------------------------------------
# [1/3] Make sure the DX Studio Player engine is installed
# ---------------------------------------------------------------------------
$candidates = @(
    (Join-Path $PSScriptRoot $setupFileName),
    (Join-Path $gameDir $setupFileName),
    (Join-Path $env:TEMP "baron-wittard-fix\$setupFileName")
) | Select-Object -Unique

if ($Uninstall) {
    Remove-DXStudioPlayer
    exit 0
}

Write-Host "[1/3] Checking DX Studio Player engine..."
$installed = Test-DXStudioPlayerInstalled

if ($installed -and -not $Force) {
    Write-Host "      Engine already present ($playerDir)."
}
else {
    if ($SkipInstall) {
        Write-Warning "Engine missing but -SkipInstall was used - the game will not render."
    }
    else {
        Write-Host "      Preparing the DX Studio Player setup..."
        $setup = $null

        # 1) offline-first: a setup file provided via -SetupPath, stored next to the
        #    fixer, in the game folder or cached in %TEMP% is verified and used directly.
        $cand  = $null
        if ($SetupPath -and (Test-Path -LiteralPath $SetupPath)) { $cand = $SetupPath }
        else { $cand = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1 }
        if ($cand) {
            $candOk = ((Get-Item -LiteralPath $cand).Length -ge $setupMinSize) -and
                      ((Get-FileHash -LiteralPath $cand -Algorithm SHA256).Hash -eq $setupSha256)
            if ($candOk) {
                Write-Host "      Using bundled setup: $cand"
                if (-not $Force) { $setup = $cand }
            }
            else {
                Write-Warning "  Bundled setup failed verification - downloading a fresh copy instead."
            }
        }

        # 2) download fallback (also used with -Force to refresh)
        if (-not $setup) {
            Write-Host "      Downloading the official setup (~20 MB)..."
            $zipDir   = Join-Path $env:TEMP 'baron-wittard-fix'
            $dlSetup  = Join-Path $zipDir $setupFileName
            New-Item -ItemType Directory -Path $zipDir -Force | Out-Null
            Remove-Item -LiteralPath $dlSetup -Force -ErrorAction SilentlyContinue

            try {
                if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
                    & curl.exe -sL --retry 3 --retry-delay 2 --max-time 500 -A "Mozilla/5.0" -o $dlSetup $setupUrl
                }
                else {
                    Invoke-WebRequest -Uri $setupUrl -OutFile $dlSetup -UseBasicParsing -TimeoutSec 500
                }
            }
            catch {
                Write-Warning "Download failed: $($_.Exception.Message)"
            }

            $dlOk = (Test-Path -LiteralPath $dlSetup) -and
                    ((Get-Item -LiteralPath $dlSetup).Length -ge $setupMinSize) -and
                    ((Get-FileHash -LiteralPath $dlSetup -Algorithm SHA256).Hash -eq $setupSha256)
            if ($dlOk) {
                $setup = $dlSetup
                Write-Host "      Integrity verified (SHA256 match, $((Get-Item -LiteralPath $dlSetup).Length) bytes)."
            }
            else {
                if ($cand -and ((Get-Item -LiteralPath $cand).Length -ge $setupMinSize)) {
                    $setup = $cand
                    Write-Warning "  Download failed or mismatched - falling back to the bundled setup."
                }
            }
        }

        if (-not $setup) {
            Write-Warning "No usable setup is available (download failed and no bundled copy found)."
            Write-Warning "Manual alternative - download this file with a browser and save it to:"
            Write-Warning "    $(Join-Path $env:TEMP "baron-wittard-fix\$setupFileName")"
            Write-Warning "Then re-run this script. Source: $setupUrl"
            exit 1
        }

        if (-not (Install-DXStudioPlayer $setup)) { exit 1 }

        if (-not (Test-DXStudioPlayerInstalled)) {
            Write-Warning "The engine still does not appear installed after setup - please check the UAC prompt and re-run."
            exit 1
        }
        Write-Host "      DX Studio Player v3.2.77 installed successfully."
    }
}

# ---------------------------------------------------------------------------
# [2/3] Summary
# ---------------------------------------------------------------------------
Write-Host "[2/3] Setup check complete."

# ---------------------------------------------------------------------------
# [3/3] Launch the game
# ---------------------------------------------------------------------------
$gameExe = Join-Path $gameDir 'baron_wittard.exe'
if ($NoLaunch) {
    Write-Host "[3/3] -NoLaunch used - game not started."
}
elseif (Test-Path -LiteralPath $gameExe) {
    Write-Host "[3/3] Starting the game..."
    Start-Process -FilePath $gameExe
    Write-Host "      Game launched. If a black window stays for more than 20 seconds,"
    Write-Host "      re-run this script and pick -Force."
}
else {
    Write-Warning "baron_wittard.exe not found in $gameDir"
    Write-Warning "Place this fixer inside the game folder (next to baron_wittard.exe) and run it again."
    exit 1
}

Write-Host ""
Write-Host "Done."
exit 0