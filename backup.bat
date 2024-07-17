@echo off

powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force"
cd path_to_your_script
start /min powershell -NoExit -Command ".\backup_script.ps1" 

:CHECK_PROCESS
tasklist /FI "IMAGENAME eq obsidian.exe" 2>NUL | find /I /N "obsidian.exe">NUL
if "%ERRORLEVEL%"=="0" (
    timeout /T 100 /NOBREAK > NUL
    goto CHECK_PROCESS
)

taskkill /IM powershell.exe /F

exit
