# Baron Wittard: Nemesis of Ragnarok — Fix & Launcher

[![Donate](https://img.shields.io/badge/Donate-PayPal-0070BA)](https://www.paypal.com/donate/?hosted_button_id=CFANQH892RPH2)

One-click repair for **Baron Wittard: Nemesis of Ragnarok** (2011) not starting on Windows 10/11.

The game is built on the **DX Studio engine**, but the player's **DX Studio Player** runtime is *not* bundled with the game. The game's launcher downloads and installs it from `www.dxstudio.com` at first run — and that server has been offline (HTTP **502**), so on modern machines the game sits in the background with no window, forever.

This release bundles the **official Worldweaver installer** (`vendor\DXStudioPlayerSetup.exe`, SHA256-pinned) next to the fixer, so the engine can be installed **fully offline**. If that bundled copy is missing, the script falls back to the Internet Archive and verifies the download before running anything.

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
2. If missing, it first uses the **bundled** setup shipped next to the fixer (`DXStudioPlayerSetup.exe`), verified with a pinned **SHA256** checksum — no download, works offline.
3. If the bundled copy is absent, it downloads the official **DX Studio Player v3.2.77** setup (≈ 20 MB) from the **Internet Archive** and verifies it (pinned SHA256) before use.
4. Installs it **silently** (elevated, so a UAC prompt appears — click **Yes**).
5. Launches the game.

## Quick Install

1. Put the whole fix folder (or the files) **inside the game folder** (next to `baron_wittard.exe`, which is where setup normally lives — e.g. `X:\Games\PC\Baron Wittard Nemesis Of Ragnarok\`).
2. Double-click `Baron_Wittard_Fix_and_Play.bat`.
3. Accept the **UAC** prompt when the engine installs.
4. The game starts.

> Because the installer is bundled with the fixer, the install works **offline** — nothing needs to be downloaded. Keep `DXStudioPlayerSetup.exe` next to the fixer.

## Manual Install

Run the PowerShell script directly (equivalent):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\baron-wittard-fix.ps1
```

Flags:

| Flag           | Meaning                                                        |
|----------------|----------------------------------------------------------------|
| `-Force`       | Re-run the setup even if the engine is already present.       |
| `-SkipInstall` | Never install the engine — only check and launch the game.    |
| `-NoLaunch`    | Only run checks, do not start the game (testing).             |
| `-Uninstall`   | Remove the installed DX Studio Player engine, then exit.      |
| `-SetupPath`   | Use this exact `.exe` instead of the bundled/downloaded one.  |

## Uninstall

Two equivalent ways to remove the engine:

1. **Companion script** — double-click `Baron_Wittard_Uninstall.bat` (accept the UAC prompt).
2. **Manual** — run `powershell -NoProfile -ExecutionPolicy Bypass -File .\baron-wittard-fix.ps1 -Uninstall`

Both run the silent uninstaller, remove the `C:\Program Files\Worldweaver\DX Studio Player` leftovers and the related registry entries. You can also remove the engine via **Settings → Apps → installed apps →** `DX Studio Player v3.2.77`, and (optionally) `PhysX / AGEIA Technologies` — installed alongside the engine exactly as the original game disc did.

## Compatibility

- Baron Wittard: Nemesis of Ragnarok (English / Russian / other releases with the same launcher)
- Windows 10 / Windows 11 (x86 & x64)
- Any DirectX 9 capable GPU

## Troubleshooting

- **UAC declined**: accept the prompt, or run the script again.
- **"Integrity check FAILED"**: a setup file failed its SHA256 check and was rejected for safety. Re-download the bundled `DXStudioPlayerSetup.exe` from the server, or get the archive link printed in the error and re-run the script.
- **Game window still missing after install**: launch the game folder's `baron_wittard.exe` directly once, then use the launcher again.
- **Black screen / bad colors in fullscreen**: run the game in windowed mode if the engine's graphics options allow it.

## Security & Integrity Notes

- The installer is the **official Worldweaver Ltd.** product (company that authored DX Studio), archived on the public Internet Archive. The release ships a bundled copy so the install works offline.
- A **SHA256** checksum is pinned to the exact verified build — a tampered or corrupted file is **rejected** and never executed.
- The only possible network activity is a fallback download of that single archived file; no telemetry.
- The repository contains **no game files** (copyright) — only the fix tooling, the engine installer and documentation.

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
