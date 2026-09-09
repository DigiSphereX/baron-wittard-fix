param(
    [switch]$Force,        # force re-download & re-install of the DX Studio Player even if it is detected
    [switch]$SkipInstall,  # never download/install the engine, only check and launch the game
    [switch]$NoLaunch      # do not start the game afterwards (useful for testing)
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
# [1/3] Make sure the DX Studio Player engine is installed
# ---------------------------------------------------------------------------
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
        Write-Host "      Engine missing - downloading the official setup (~20 MB)..."
        $zipDir  = Join-Path $env:TEMP 'baron-wittard-fix'
        $setup   = Join-Path $zipDir $setupFileName
        New-Item -ItemType Directory -Path $zipDir -Force | Out-Null
        Remove-Item -LiteralPath $setup -Force -ErrorAction SilentlyContinue

        try {
            if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
                & curl.exe -sL --retry 3 --retry-delay 2 --max-time 500 -A "Mozilla/5.0" -o $setup $setupUrl
            }
            else {
                Invoke-WebRequest -Uri $setupUrl -OutFile $setup -UseBasicParsing -TimeoutSec 500
            }
        }
        catch {
            Write-Warning "Download failed: $($_.Exception.Message)"
        }

        if (-not (Test-Path -LiteralPath $setup) -or (Get-Item -LiteralPath $setup).Length -lt $setupMinSize) {
            Write-Warning "The archive download was incomplete or failed."
            Write-Warning "Manual alternative - download this file with a browser and save it to:"
            Write-Warning "    $setup"
            Write-Warning "Then re-run this script. Source: $setupUrl"
            exit 1
        }

        $hash = (Get-FileHash -LiteralPath $setup -Algorithm SHA256).Hash
        if ($hash -ne $setupSha256) {
            $tmp = Join-Path $zipDir 'corrupt.invalid'
            Move-Item -LiteralPath $setup $tmp -Force -ErrorAction SilentlyContinue
            Write-Warning "Integrity check FAILED."
            Write-Warning "Expected SHA256 : $setupSha256"
            Write-Warning "Got             : $hash"
            Write-Warning "Download rejected for safety. Your copy of archive.org did not match the pinned file."
            exit 1
        }
        Write-Host "      Integrity verified (SHA256 match, $((Get-Item -LiteralPath $setup).Length) bytes)."

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