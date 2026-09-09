@echo off
title Baron Wittard - Fix & Play
color 0A
echo ============================================
echo   Baron Wittard: Nemesis of Ragnarok
echo   Fix & Launcher - Windows 10 / 11
echo   Repairs the missing DX Studio Player
echo   engine and starts the game.
echo ============================================
echo.

where powershell >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] PowerShell not found on this system.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0baron-wittard-fix.ps1" %*
if errorlevel 1 (
    echo.
    echo [!] Something went wrong - see the messages above.
    pause
    exit /b 1
)

echo.
exit /b 0