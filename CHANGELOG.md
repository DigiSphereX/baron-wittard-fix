# Changelog

All notable changes to this project are documented here.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.1] - 2026-09-14

### Added
- **Bundled offline installer** (`vendor\DXStudioPlayerSetup.exe`, SHA256-pinned): the engine installs from the copy shipped with the fixer — no download needed, works on machines without Internet. The script now looks for the setup next to the fixer / in the game folder first (`-SetupPath` to force a specific file).
- **`-Uninstall` switch + `Baron_Wittard_Uninstall.bat`**: removes the installed DX Studio Player engine (silent uninstaller, leftover folder, registry entries, cached download) so it can be cleaned up later if desired.

### Fixed
- **Batch-file syntax errors on first run** (`'Play' is not recognized`, `'Launcher' is not recognized`): the `&` in the `title`/`echo` lines was parsed as a command separator — now correctly escaped (`^&`).