@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_godot_tests.ps1" %*
