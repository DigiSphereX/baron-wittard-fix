@echo off
title Baron Wittard - Uninstall DX Studio Player
color 0E
echo ============================================
echo   Baron Wittard: Nemesis of Ragnarok
echo   Uninstall DX Studio Player engine
echo   (run this later if you want to remove it)
echo ============================================
echo.

where powershell >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] PowerShell not found on this system.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0baron-wittard-fix.ps1" -Uninstall
if errorlevel 1 (
    echo.
    echo [!] Something went wrong - see the messages above.
    pause
    exit /b 1
)

pause