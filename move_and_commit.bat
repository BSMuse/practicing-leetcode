@echo off
setlocal EnableDelayedExpansion

REM Define directories and initial settings
set "SOURCE_DIR=C:\Users\Admin\Documents\repos\Leetcode"
set "REPO_DIR=C:\Users\Admin\Documents\repos\practicing-leetcode"
set "START_DATE=2025-02-19"
set "COUNT=0"

REM Check if the repository directory exists
if not exist "%REPO_DIR%" (
    echo ERROR: Repository directory "%REPO_DIR%" does not exist.
    exit /b 1
)

REM Change to the repository directory
cd /d "%REPO_DIR%"

REM Sync with remote repository without resetting or cleaning (preserves existing files)
echo Syncing with remote repository https://github.com/BSMuse/practicing-leetcode.git...
git pull origin master
if !errorlevel! neq 0 (
    echo ERROR: Failed to sync with remote repository. Check Git configuration.
    exit /b !errorlevel!
)
echo Repository synced successfully.

REM Ensure move_and_commit.bat is tracked by Git (add and commit if not already tracked)
if not exist ".git" (
    echo Initializing Git repository...
    git init
    git remote add origin https://github.com/BSMuse/practicing-leetcode.git
)
if not exist ".gitignore" (
    echo Creating .gitignore to exclude unnecessary files...
    echo *.log > .gitignore
    echo *.tmp >> .gitignore
    git add .gitignore
)
git add move_and_commit.bat 2>nul
if !errorlevel! equ 0 (
    git commit -m "Add move_and_commit.bat script" --date="%START_DATE% 00:00:00 -0000"
    if !errorlevel! neq 0 (
        echo WARNING: Failed to commit move_and_commit.bat. Continuing...
    )
)

REM Check if source directory exists
if not exist "%SOURCE_DIR%" (
    echo ERROR: Source directory "%SOURCE_DIR%" does not exist.
    exit /b 1
)

REM Enhanced debugging for source directory and folders
echo Checking source directory: "%SOURCE_DIR%"
dir "%SOURCE_DIR%" /a

REM Process each folder containing LeetCode solutions (e.g., 1-100q, 100-200q, etc.)
echo Searching for folders matching "%SOURCE_DIR%\*-*q"...
for %%D in ("%SOURCE_DIR%\*-*q") do (
    echo Found folder: "%%D"
    echo Checking for .py files in "%%D"...
    dir "%%D\*.py" /a

    for %%F in ("%%D\*.py") do (
        set /a "COUNT+=1"
        set "FILENAME=%%~nxF"
        REM Extract problem number from filename (e.g., 03.py -> 3)
        set "PROBLEM_NUMBER=%%~nF"  REM Get filename without extension
        REM Remove leading zeros if needed
        :remove_leading_zeros
        if "!PROBLEM_NUMBER:~0,1!"=="0" (
            set "PROBLEM_NUMBER=!PROBLEM_NUMBER:~1!"
            goto remove_leading_zeros
        )
        echo Copied !FILENAME! from "%%D" to %REPO_DIR%

        REM Copy the file to the repository directory
        copy "%%F" "%REPO_DIR%\!FILENAME!" >nul
        if !errorlevel! neq 0 (
            echo ERROR: Failed to copy !FILENAME! to %REPO_DIR%. Check permissions or path.
            exit /b !errorlevel!
        )

        REM Generate backdated timestamp using PowerShell
        for /f "tokens=*" %%A in ('powershell -Command "[DateTime]::ParseExact(\\\"%START_DATE%\\\", \\\"yyyy-MM-dd\\\", $null).AddDays(-!COUNT!).ToString(\\\"MMM dd, yyyy\\\")"') do set "HUMAN_DATE=%%A"
        for /f "tokens=*" %%A in ('powershell -Command "[DateTime]::ParseExact(\\\"%START_DATE%\\\", \\\"yyyy-MM-dd\\\", $null).AddDays(-!COUNT!).ToString(\\\"yyyy-MM-dd HH:mm:ss -0000\\\")"') do set "BACKDATE_TIMESTAMP=%%A"

        REM Debug output for verification
        echo Debug: Extracted PROBLEM_NUMBER = !PROBLEM_NUMBER!
        echo Debug: Human Date Output = !HUMAN_DATE!
        echo Debug: PowerShell Timestamp Output = !BACKDATE_TIMESTAMP!
        echo Debug: Backdate Timestamp for !FILENAME! is !BACKDATE_TIMESTAMP!
        echo Debug: Human Date for !FILENAME! is !HUMAN_DATE!
        echo Debug: Git Date set to !BACKDATE_TIMESTAMP!

        REM Commit the file with backdated timestamp
        echo Debug: Git Commit Command = git commit -m "Add LeetCode solution !PROBLEM_NUMBER! on !HUMAN_DATE!" --date="!BACKDATE_TIMESTAMP!" !FILENAME!
        git commit -m "Add LeetCode solution !PROBLEM_NUMBER! on !HUMAN_DATE!" --date="!BACKDATE_TIMESTAMP!" !FILENAME!
        if !errorlevel! neq 0 (
            echo ERROR: Failed to commit !FILENAME! with backdated timestamp. Check Git configuration.
            exit /b !errorlevel!
        )

        REM Push to remote repository
        git push origin master
        if !errorlevel! neq 0 (
            echo ERROR: Failed to push !FILENAME! to remote repository.
            exit /b !errorlevel!
        )
    )
)

if !COUNT! equ 0 (
    echo WARNING: No LeetCode solution files (.py) were found or processed. Check the source directory, folder structure, and file visibility.
    echo Verify folder names match *-*q (e.g., 1-100q, 100-200q) and contain .py files.
    exit /b 1
)

echo All files processed, committed, and pushed with backdated timestamps. Total files processed: !COUNT!
endlocal