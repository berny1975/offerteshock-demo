@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
cd /d "%~dp0"

REM -------- CONFIG --------
set "REPONAME=offerteshock-demo"
set "VISIBILITY=public"
if "%VISIBILITY%"=="" set "VISIBILITY=public"
REM ------------------------

echo Working folder: "%CD%"
echo Repo name: %REPONAME%
echo Visibility: %VISIBILITY%
echo.

echo %CD% | find /I "\Windows\" >nul
if not errorlevel 1 (
  echo ERRORE: Non eseguire in C:\Windows\... Sposta la cartella in Download/Documenti/Desktop.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publish_corrected.ps1" -RepoName "%REPONAME%" -Visibility "%VISIBILITY%"
echo.
echo Completato. Premi un tasto per chiudere...
pause >nul
