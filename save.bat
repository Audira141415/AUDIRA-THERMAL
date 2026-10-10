@echo off
setlocal enabledelayedexpansion

title Save and Sync AUDIRA-THERMAL
cd /d "%~dp0"

echo ========================================================
echo        AUDIRA THERMAL - SAVE & PUSH WORKSPACE
echo ========================================================
echo.

set REPO_URL=https://github.com/Audira141415/AUDIRA-THERMAL.git

:: Check current branch name
for /f "tokens=*" %%b in ('git branch --show-current 2^>nul') do set CURRENT_BRANCH=%%b
if "%CURRENT_BRANCH%"=="" set CURRENT_BRANCH=master
echo Cabang aktif saat ini: %CURRENT_BRANCH%

:: Stage all changes
echo.
echo [1/3] Menambahkan perubahan file (git add .)...
git add .

:: Commit message
set COMMIT_MSG=%*
if "%COMMIT_MSG%"=="" (
    set COMMIT_MSG=chore: save changes and sync workspace
)

echo.
echo [2/3] Melakukan commit: "%COMMIT_MSG%"...
git commit -m "%COMMIT_MSG%"

:: Push to remote
echo.
echo [3/3] Mendorong ke GitHub (%CURRENT_BRANCH%)...
git push origin %CURRENT_BRANCH%
if %errorlevel% neq 0 (
    echo Mencoba git pull --rebase lalu push kembali...
    git pull origin %CURRENT_BRANCH% --rebase
    git push -u origin %CURRENT_BRANCH%
)

echo.
echo ========================================================
echo  SELESAI! Perubahan berhasil disimpan ke GitHub.
echo ========================================================
echo.
