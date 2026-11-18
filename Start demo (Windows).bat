@echo off
rem Double-click to start the Chekin guest app demo (works without internet).
cd /d "%~dp0"
start "" /min cmd /c "timeout /t 2 /nobreak >nul & start http://localhost:7900/"
powershell -NoProfile -ExecutionPolicy Bypass -File "tools\server.ps1" 7900 "%~dp0."
