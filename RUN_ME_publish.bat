@echo off
setlocal
REM === Offerteshock Multipage One-Click (v1.4, remote-first) ===
set REPONAME=offerteshock-demo
set VISIBILITY=public

powershell -NoProfile -Command "Unblock-File -LiteralPath '%~dp0publish.ps1'" 2>nul
powershell -ExecutionPolicy Bypass -File "%~dp0publish.ps1" -RepoName "%REPONAME%" -Visibility %VISIBILITY%
echo.
echo Premi un tasto per chiudere...
pause >nul
