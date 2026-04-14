@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0clear_godot_cache.ps1" %*
set "exit_code=%ERRORLEVEL%"
if not "%exit_code%"=="0" (
  echo.
  echo clear_godot_cache failed with exit code %exit_code%.
  pause
)
exit /b %exit_code%
