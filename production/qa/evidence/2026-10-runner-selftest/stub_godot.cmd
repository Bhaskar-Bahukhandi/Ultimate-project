@echo off
rem Stub for Godot (TD-010 PowerShell self-test). Called as: stub_godot.cmd --headless --path P --script S
rem Arguments are ignored. STUB_FIXTURE = text file to print, STUB_MARKER = file to create when run,
rem STUB_EXIT = exit code (default 0). Lines are printed from a file because cmd cannot echo % < > | & ^ reliably.
setlocal
if "%STUB_EXIT%"=="" set STUB_EXIT=0
if defined STUB_MARKER echo x> "%STUB_MARKER%"
type "%STUB_FIXTURE%"
exit /b %STUB_EXIT%
