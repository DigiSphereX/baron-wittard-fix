# Baron Wittard: Nemesis of Ragnarok — Fix & Launcher

[![Donate](https://img.shields.io/badge/Donate-PayPal-0070BA)](https://www.paypal.com/donate/?hosted_button_id=CFANQH892RPH2)

One-click repair for **Baron Wittard: Nemesis of Ragnarok** (2011) not starting on Windows 10/11.

The game is built on the **DX Studio engine**, but the player's **DX Studio Player** runtime is *not* bundled with the game. The game's launcher downloads and installs it from `www.dxstudio.com` at first run — and that server has been offline (HTTP **502**), so on modern machines the game sits in the background with no window, forever.

This tool downloads the **official Worldweaver installer** from the Internet Archive, verifies its SHA256 checksum, installs it silently, and then launches the game.

## The Problem

```
Error opening http://www.dxstudio.com/downloads/player/vLatest/DXStudioPlayerSetup.exe.

The server returned status code 502.
```

or the symptom on Windows 11:

- `baron_wittard.exe` starts, but **no game window ever appears** and nothing happens.

**Why:** `baron_wittard.exe` is only a *launcher*. It extracts `DXStudioPlayerSetupWeb.exe` to `%TEMP%` and runs it. That web-setup tries to download the full player installer from `dxstudio.com` — whose backend is dead (returns 502). The engine is never installed, so the game has nothing to render the `.dxscene` scenes with.

## The Fix

1. Detects whether **DX Studio Player** is already installed (folder + registry).
2. If missing, downloads the official **DX Studio Player v3.2.77** setup (≈ 20 MB) from the **Internet Archive** (`web.archive.org`, the archived copy of the original file on `dxstudio.com`).
3. Verifies the file with a pinned **SHA256** checksum before running it.
4. Installs it **silently** (elevated, so a UAC prompt appears — click **Yes**).
5. Launches the game.

## Quick Install

1. Put `Baron_Wittard_Fix_and_Play.bat` and `baron-wittard-fix.ps1` **inside the game folder** (next to `baron_wittard.exe`).
2. Double-click `Baron_Wittard_Fix_and_Play.bat`.
3. Accept the **UAC** prompt when the engine installs.
4. The game starts.

> First run downloads ~20 MB and takes a few minutes to install. Later runs are instant.

## Manual Install

Run the PowerShell script directly (equivalent):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\baron-wittard-fix.ps1
```

Flags:

| Flag           | Meaning                                                        |
|----------------|----------------------------------------------------------------|
| `-Force`       | Re-download and re-install the engine even if it is present.  |
| `-SkipInstall` | Never install the engine — only check and launch the game.    |
| `-NoLaunch`    | Only run checks, do not start the game (testing).             |

## Uninstall

- Remove the engine: **Settings → Apps → installed apps →** `DX Studio Player v3.2.77`.
- (Optionally) remove PhysX: `AGEIA Technologies` in the same list — installed alongside the engine exactly as the original game disc did.

## Compatibility

- Baron Wittard: Nemesis of Ragnarok (English / Russian / other releases with the same launcher)
- Windows 10 / Windows 11 (x86 & x64)
- Any DirectX 9 capable GPU

## Troubleshooting

- **UAC declined**: accept the prompt, or run the script again.
- **"Integrity check FAILED"**: the file downloaded from the archive did not match the expected checksum — the download is rejected for safety. Simply re-run; if it persists, download `DXStudioPlayerSetup.exe` manually from the URL printed by the script into the same folder and re-run.
- **Game window still missing after install**: launch the game folder's `baron_wittard.exe` directly once, then use the launcher again.
- **Black screen / bad colors in fullscreen**: run the game in windowed mode if the engine's graphics options allow it.

## Security & Integrity Notes

- The installer is the **official Worldweaver Ltd.** product (company that authored DX Studio), archived on the public Internet Archive.
- A **SHA256** checksum is pinned to the exact verified build — a tampered or corrupted download is **rejected** and never executed.
- Nothing else is downloaded; no telemetry, no network activity beyond the single archived file.
- The repository contains **no game files** (copyright) — only the fix tooling and documentation.

## Disclaimer / Backup advice

Use this fix at your own risk. Before applying it: read the scripts (everything here
is plain, readable source), **back up** the game folder / registry areas it touches,
and create a system restore point. A fix that works on most machines can behave
unexpectedly on a specific setup. The author is not responsible for any
unintentional damage or data loss.

## License

MIT — see [LICENSE](LICENSE). Game content is © Iceberg Interactive / the original owners.

---

## ☕ Support this project

Free and open source (MIT). If this project saved you time or money, consider a small thank-you:

- **GitHub Sponsors** -> https://github.com/sponsors/DigiSphereX
- **PayPal** -> https://www.paypal.com/donate/?hosted_button_id=CFANQH892RPH2
