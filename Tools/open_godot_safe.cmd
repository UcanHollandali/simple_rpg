@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0open_godot_safe.ps1" %*
set "exit_code=%ERRORLEVEL%"
if not "%exit_code%"=="0" (
  echo.
  echo open_godot_safe failed with exit code %exit_code%.
  echo Check the repo-local log under _godot_profile\logs\godot_editor.log
  pause
)
exit /b %exit_code%
