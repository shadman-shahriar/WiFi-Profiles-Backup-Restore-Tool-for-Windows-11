@echo off
title WiFi Profiles Backup & Restore Tool (Windows 11)
color 0A
setlocal enabledelayedexpansion

:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell start -verb runas '%0'
    exit /b
)

:menu
cls
echo =======================================================
echo    WiFi Profiles Backup Restore Tool - Windows 11
echo               created by: Shadman Shahriar
echo =======================================================
echo.
echo  [1] Backup all saved WiFi profiles (SSID + Password)
echo  [2] Restore WiFi profiles from backup file
echo  [3] Exit
echo.
set /p choice="Enter your choice (1/2/3): "

if "%choice%"=="1" goto backup
if "%choice%"=="2" goto restore_prompt
if "%choice%"=="3" exit
echo Invalid choice. Please try again.
timeout /t 2 >nul
goto menu

:backup
cls
echo =======================================================
echo    WiFi Profiles Backup Restore Tool - Windows 11
echo               created by: Shadman Shahriar
echo =======================================================
echo.
echo Current date/time will be used in filename: WiFi_Backup_YYYYMMDD.csv
echo.
set "default_path=%userprofile%\Desktop"
echo Default save location: %default_path%
echo.
set /p "backup_path=Enter full directory path (or press Enter to use default): "
if "%backup_path%"=="" set "backup_path=%default_path%"

:: Create directory if it doesn't exist
if not exist "%backup_path%" mkdir "%backup_path%" 2>nul
if not exist "%backup_path%" (
    echo ERROR: Cannot create or access directory "%backup_path%"
    pause
    goto menu
)

set "backup_file=%backup_path%\WiFi_Backup_%date:~10,4%%date:~4,2%%date:~7,2%.csv"
echo.
echo Creating backup at: %backup_file%

:: Write CSV header
echo "SSID","Authentication","Encryption","Key" > "%backup_file%"

:: Export all WiFi profiles
for /f "skip=4 tokens=1* delims=:" %%a in ('netsh wlan show profiles') do (
    set "ssid=%%b"
    set "ssid=!ssid:~1!"
    if defined ssid (
        for /f "tokens=2 delims=:" %%c in ('netsh wlan show profile name^="!ssid!" key^=clear ^| findstr /c:"Key Content"') do (
            set "key=%%c"
            set "key=!key:~1!"
        )
        for /f "tokens=2 delims=:" %%c in ('netsh wlan show profile name^="!ssid!" ^| findstr /c:"Authentication"') do set "auth=%%c"
        for /f "tokens=2 delims=:" %%c in ('netsh wlan show profile name^="!ssid!" ^| findstr /c:"Cipher"') do set "cipher=%%c"
        echo "!ssid!","!auth:~1!","!cipher:~1!","!key!" >> "%backup_file%"
        set "auth="
        set "cipher="
        set "key="
    )
)

echo.
echo Backup completed successfully!
echo File saved to: %backup_file%
echo.
pause
goto menu

:restore_prompt
cls
echo =======================================================
echo    WiFi Profiles Backup Restore Tool - Windows 11
echo               created by: Shadman Shahriar
echo =======================================================
echo =============== RESTORE WIFI PROFILES ===============
echo.
echo Type BACK and press Enter to return to main menu.
echo Or press Enter to continue with restore.
echo.
set /p "restore_choice=Type BACK or press Enter: "
if /i "%restore_choice%"=="BACK" goto menu
goto restore

:restore
cls
echo =======================================================
echo    WiFi Profiles Backup Restore Tool - Windows 11
echo               created by: Shadman Shahriar
echo =======================================================
echo.
echo Please enter the full path of the backup CSV file:
echo (e.g., C:\Users\YourName\Desktop\WiFi_Backup_20250228.csv)
echo.
echo Tip: You can also drag and drop the file into this window.
echo.
set /p "csv_path=Path (or type BACK to go home): "
if /i "%csv_path%"=="BACK" goto menu

if not exist "%csv_path%" (
    echo File not found. Please check the path.
    pause
    goto restore_prompt
)

cls
echo Restoring WiFi profiles from: %csv_path%
echo.

:: Skip header and read each line
for /f "skip=1 tokens=1-4 delims=," %%a in ('type "%csv_path%"') do (
    set "ssid=%%a"
    set "auth=%%b"
    set "enc=%%c"
    set "key=%%d"
    
    :: Remove surrounding quotes
    set "ssid=!ssid:"=!"
    set "auth=!auth:"=!"
    set "enc=!enc:"=!"
    set "key=!key:"=!"
    
    echo Restoring SSID: !ssid!
    
    :: Create profile XML temporarily
    set "xml_file=%temp%\!ssid!.xml"
    (
        echo ^<?xml version="1.0"?^>
        echo ^<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1"^>
        echo   ^<name^>!ssid!^</name^>
        echo   ^<SSIDConfig^>
        echo     ^<SSID^>
        echo       ^<name^>!ssid!^</name^>
        echo     ^</SSID^>
        echo   ^</SSIDConfig^>
        echo   ^<connectionType^>ESS^</connectionType^>
        echo   ^<connectionMode^>auto^</connectionMode^>
        echo   ^<MSM^>
        echo     ^<security^>
        echo       ^<authEncryption^>
        echo         ^<authentication^>!auth!^</authentication^>
        echo         ^<encryption^>!enc!^</encryption^>
        echo         ^<useOneX^>false^</useOneX^>
        echo       ^</authEncryption^>
        echo       ^<sharedKey^>
        echo         ^<keyType^>passPhrase^</keyType^>
        echo         ^<protected^>false^</protected^>
        echo         ^<keyMaterial^>!key!^</keyMaterial^>
        echo       ^</sharedKey^>
        echo     ^</security^>
        echo   ^</MSM^>
        echo ^</WLANProfile^>
    ) > "!xml_file!"
    
    netsh wlan add profile filename="!xml_file!" >nul 2>&1
    del "!xml_file!" 2>nul
)

echo.
echo Restore completed! Check your WiFi networks.
pause
goto menu