@echo off
setlocal enabledelayedexpansion

REM --- Configuration ---
set SOURCE_DIR=.
set BUILD_TYPE=release
set STATIC_LINK_ARGS=-static
set ARCHITECTURES=x64 x86 arm64
set BUILD_DIR_PREFIX=build/build_static_
set OUTPUT_LIB_NAME=webrtc_audio_processing
REM --- End Configuration ---

REM --- Check prerequisites ---
where meson >nul 2>nul || (
    echo ERROR: 'meson' command not found. Please install Meson.
    exit /b 1
)
where ninja >nul 2>nul || (
    echo ERROR: 'ninja' command not found. Please install Ninja.
    exit /b 1
)

echo --- WebRTC Audio Processing Build Script ---
echo Building for architectures: %ARCHITECTURES%
echo.

REM Verify we have at least one architecture to build
if "%ARCHITECTURES%"=="" (
    echo ERROR: No architectures specified in ARCHITECTURES
    exit /b 1
)

set EXIT_CODE=0
for %%a in (%ARCHITECTURES%) do (
    echo.
    echo === Building for %%a ===

    set "BUILD_DIR=%BUILD_DIR_PREFIX%%%a"

    REM Clean previous build
    if exist "!BUILD_DIR!" (
        echo Removing existing !BUILD_DIR!...
        rmdir /s /q "!BUILD_DIR!"
    )

    REM Configure build
    echo Configuring %%a build...
    echo Using meson: %MESON_PATH%
    where meson

    if "%%a"=="arm64" (
        meson setup "!BUILD_DIR!" "%SOURCE_DIR%" ^
            --buildtype=%BUILD_TYPE% ^
            --cross-file "%SOURCE_DIR%\cross_arm64.txt"
    ) else if "%%a"=="x86" (
        meson setup "!BUILD_DIR!" "%SOURCE_DIR%" ^
            --buildtype=%BUILD_TYPE% ^
            --cross-file "%SOURCE_DIR%\cross_win32.txt" ^
            -Dc_args="-m32 -msse2" ^
            -Dcpp_args="-m32 -msse2" ^
            -Dc_link_args="%STATIC_LINK_ARGS% -m32" ^
            -Dcpp_link_args="%STATIC_LINK_ARGS% -m32"
    ) else (
        meson setup "!BUILD_DIR!" "%SOURCE_DIR%" ^
            --buildtype=%BUILD_TYPE% ^
            -Dc_args="-m64" ^
            -Dcpp_args="-m64" ^
            -Dc_link_args="%STATIC_LINK_ARGS% -m64" ^
            -Dcpp_link_args="%STATIC_LINK_ARGS% -m64"
    )

    if errorlevel 1 (
        echo ERROR: Configuration failed for %%a
        set EXIT_CODE=1
        goto :end
    )

    REM Build
    echo Building %%a version...
    ninja -C "!BUILD_DIR!"

    if errorlevel 1 (
        echo ERROR: Build failed for %%a
        set EXIT_CODE=1
        goto :end
    )

    echo Successfully built %%a version in !BUILD_DIR!
)

:end
endlocal & exit /b %EXIT_CODE%