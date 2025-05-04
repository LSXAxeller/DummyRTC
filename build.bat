@echo off
setlocal enabledelayedexpansion

REM --- Configuration ---
set SOURCE_DIR=.
set BUILD_TYPE=release
set STATIC_LINK_ARGS=-static
set ARCHITECTURES=x64 x86 arm64 arm32
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

    if "%%a"=="x86" (
        meson setup "!BUILD_DIR!" "%SOURCE_DIR%" ^
            --buildtype=%BUILD_TYPE% ^
            --cross-file "%SOURCE_DIR%\cross_win32.txt" ^
            -Dc_args="-m32 -msse2" ^
            -Dcpp_args="-m32 -msse2" ^
            -Dc_link_args="%STATIC_LINK_ARGS% -m32" ^
            -Dcpp_link_args="%STATIC_LINK_ARGS% -m32"
    ) else if "%%a"=="arm64" (
        meson setup "!BUILD_DIR!" "%SOURCE_DIR%" ^
            --buildtype=%BUILD_TYPE% ^
            --cross-file "%SOURCE_DIR%\cross_arm64.txt"
    ) else if "%%a"=="arm32" (
        meson setup "!BUILD_DIR!" "%SOURCE_DIR%" ^
            --buildtype=%BUILD_TYPE% ^
            --cross-file "%SOURCE_DIR%\cross_arm32.txt"
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
        exit /b 1
    )

    REM Build
    echo Building %%a version...
    ninja -C "!BUILD_DIR!"

    if errorlevel 1 (
        echo ERROR: Build failed for %%a
        exit /b 1
    )

    REM Rename output files for consistency
    if exist "!BUILD_DIR!\lib!OUTPUT_LIB_NAME!.dll" (
        copy "!BUILD_DIR!\lib!OUTPUT_LIB_NAME!.dll" "!BUILD_DIR!\!OUTPUT_LIB_NAME!_%%a.dll"
    )
    if exist "!BUILD_DIR!\lib!OUTPUT_LIB_NAME!.a" (
        copy "!BUILD_DIR!\lib!OUTPUT_LIB_NAME!.a" "!BUILD_DIR!\!OUTPUT_LIB_NAME!_%%a.a"
    )
    if exist "!BUILD_DIR!\lib!OUTPUT_LIB_NAME!.lib" (
        copy "!BUILD_DIR!\lib!OUTPUT_LIB_NAME!.lib" "!BUILD_DIR!\!OUTPUT_LIB_NAME!_%%a.lib"
    )
    
    echo Successfully built %%a version in !BUILD_DIR!
)

echo.
echo All builds completed successfully!
endlocal
exit /b 0