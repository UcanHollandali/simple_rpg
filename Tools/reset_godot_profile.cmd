@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0reset_godot_profile.ps1" %*
set "exit_code=%ERRORLEVEL%"
if not "%exit_code%"=="0" (
  echo.
  echo reset_godot_profile failed with exit code %exit_code%.
  pause
)
exit /b %exit_code%
