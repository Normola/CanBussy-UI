@echo off
REM Git pre-commit hook for Flutter/Dart projects (Windows)
REM This hook will automatically format Dart code before committing

echo 🔍 Running pre-commit checks...

REM Check if dart is available
dart --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Error: Dart is not installed or not in PATH
    echo Please install Flutter/Dart SDK first
    exit /b 1
)

REM Get list of Dart files that are staged for commit
for /f "delims=" %%i in ('git diff --cached --name-only --diff-filter=ACM') do (
    echo %%i | findstr "\.dart$" >nul
    if not errorlevel 1 (
        set "DART_FILES=!DART_FILES! %%i"
    )
)

if "%DART_FILES%"=="" (
    echo ✅ No Dart files to format
    exit /b 0
)

echo 📝 Formatting Dart files...

setlocal enabledelayedexpansion
set "FORMATTED_FILES="
set "FORMAT_FAILED=false"

REM Format each staged Dart file
for %%f in (%DART_FILES%) do (
    if exist "%%f" (
        echo   Formatting: %%f
        
        REM Run dart format on the file
        dart format "%%f" --output=write
        if !errorlevel! equ 0 (
            REM Check if the file was actually changed
            git diff --quiet "%%f"
            if !errorlevel! neq 0 (
                set "FORMATTED_FILES=!FORMATTED_FILES! %%f"
                REM Stage the formatted file
                git add "%%f"
            )
        ) else (
            echo ❌ Error formatting %%f
            set "FORMAT_FAILED=true"
        )
    )
)

REM Check if formatting failed
if "%FORMAT_FAILED%"=="true" (
    echo ❌ Pre-commit hook failed: Some files could not be formatted
    exit /b 1
)

REM Report results
if not "%FORMATTED_FILES%"=="" (
    echo ✅ Formatted and re-staged files:%FORMATTED_FILES%
    echo 📝 Files have been automatically formatted and added to the commit
) else (
    echo ✅ All Dart files were already properly formatted
)

echo 🎉 Pre-commit checks completed successfully!
exit /b 0
