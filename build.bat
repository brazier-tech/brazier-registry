@echo off
setlocal enabledelayedexpansion

if defined VCPKG_ROOT (
    set VCPKG_PATH=%VCPKG_ROOT%
) else (
    set VCPKG_PATH=C:\Tools\vcpkg
)

set SCRIPT_DIR=%~dp0
for %%I in ("%SCRIPT_DIR%.")        do set "SCRIPT_DIR=%%~fI"
for %%I in ("%SCRIPT_DIR%\..")      do set "SOURCES_DIR=%%~fI"
set PORTS_PATH=%SCRIPT_DIR%\ports

REM --- create junctions for source directories ---
call :make_junction "%PORTS_PATH%\brazier-core\source"   "%SOURCES_DIR%\brazier"
call :make_junction "%PORTS_PATH%\brazier-orm\source"    "%SOURCES_DIR%\brazierORM"
call :make_junction "%PORTS_PATH%\brazier-logger\source" "%SOURCES_DIR%\brazier-logger"

REM --- copy license files ---
call :copy_licenses "%SOURCES_DIR%\brazier"       "%PORTS_PATH%\brazier"
call :copy_licenses "%SOURCES_DIR%\brazier"       "%PORTS_PATH%\brazier-core"
call :copy_licenses "%SOURCES_DIR%\brazierORM"    "%PORTS_PATH%\brazier-orm"
call :copy_licenses "%SOURCES_DIR%\brazier-logger" "%PORTS_PATH%\brazier-logger"

"%VCPKG_PATH%\vcpkg.exe" install vcpkg-cmake vcpkg-cmake-config --recurse

REM --- clean cache for rebuild ---
call :clean_archives
call :clean_port brazier
call :clean_port brazier-core
call :clean_port brazier-orm
call :clean_port brazier-logger

REM --- remove old installs ---
"%VCPKG_PATH%\vcpkg.exe" remove brazier-logger:x64-windows --recurse --purge
"%VCPKG_PATH%\vcpkg.exe" remove brazier-orm:x64-windows    --recurse --purge
"%VCPKG_PATH%\vcpkg.exe" remove brazier-core:x64-windows   --recurse --purge
"%VCPKG_PATH%\vcpkg.exe" remove brazier:x64-windows        --recurse --purge

REM --- install ---
"%VCPKG_PATH%\vcpkg.exe" install --overlay-ports="%PORTS_PATH%" brazier --recurse --editable --no-binarycaching

endlocal
goto :eof

REM ---- helper: create a junction ----
:make_junction
set "LINK=%~1"
set "TARGET=%~2"

if exist "%LINK%" (
    rmdir "%LINK%" 2>nul
    if exist "%LINK%" (
        powershell -NoProfile -Command "Remove-Item -LiteralPath '%LINK%' -Recurse -Force -ErrorAction SilentlyContinue"
    )
)

powershell -NoProfile -Command "New-Item -ItemType Junction -Path '%LINK%' -Target '%TARGET%' | Out-Null"
echo Created junction: %LINK% -^> %TARGET%
goto :eof

REM ---- helper: copy LICENSE* / COPYING* / LGPL*/GPL* ----
:copy_licenses
set "SRC=%~1"
set "DST=%~2"

if not exist "%DST%" mkdir "%DST%"

for %%F in ("%SRC%\LICENSE*" "%SRC%\COPYING*" "%SRC%\LGPL*.txt" "%SRC%\GPL*.txt") do (
    if exist "%%~F" (
        copy /Y "%%~F" "%DST%\" >nul
        echo Copied license: %%~nxF
    )
)
goto :eof

REM ---- helper: remove buildtrees and packages for a port ----
:clean_port
set "PORT=%~1"
echo Cleaning %PORT%...
rmdir /s /q "%VCPKG_PATH%\buildtrees\%PORT%" 2>nul
rmdir /s /q "%VCPKG_PATH%\packages\%PORT%_x64-windows" 2>nul
rmdir /s /q "%VCPKG_PATH%\packages\%PORT%_x64-windows-dbg" 2>nul
rmdir /s /q "%VCPKG_PATH%\packages\%PORT%_x64-windows-rel" 2>nul
goto :eof

REM ---- helper: remove brazier archives from global binary cache ----
:clean_archives
echo Cleaning brazier archives...
powershell -NoProfile -Command ^
    "Get-ChildItem \"$env:LOCALAPPDATA\vcpkg\archives\" -Recurse -File -ErrorAction SilentlyContinue |" ^
    "Where-Object { $_.Name -match 'brazier' } |" ^
    "Remove-Item -Force -ErrorAction SilentlyContinue"
goto :eof