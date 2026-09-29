@echo off
setlocal enabledelayedexpansion

title Push AUDIRA-THERMAL to GitHub
cd /d "%~dp0"

echo ========================================================
echo        AUDIRA THERMAL - PUSH TO GITHUB REPOSITORY
echo ========================================================
echo.

set REPO_URL=https://github.com/Audira141415/AUDIRA-THERMAL.git

:: Check if git is installed
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Git tidak ditemukan di komputer ini.
    echo Silakan install Git terlebih dahulu: https://git-scm.com/
    pause
    exit /b 1
)

:: Configure remote origin
echo [1/5] Memeriksa remote origin...
git remote get-url origin >nul 2>nul
if %errorlevel% neq 0 (
    echo Menambahkan remote origin: %REPO_URL%
    git remote add origin %REPO_URL%
) else (
    echo Memperbarui URL remote origin...
    git remote set-url origin %REPO_URL%
)

:: Check current branch name
for /f "tokens=*" %%b in ('git branch --show-current 2^>nul') do set CURRENT_BRANCH=%%b
if "%CURRENT_BRANCH%"=="" set CURRENT_BRANCH=master
echo Cabang aktif saat ini: %CURRENT_BRANCH%

:: Stage all changes
echo.
echo [2/5] Menambahkan perubahan file (git add .)...
git add .

:: Commit message
set COMMIT_MSG=%*
if "%COMMIT_MSG%"=="" (
    set COMMIT_MSG=feat: update bluetooth scanning, auto-connect, receipt templates, and release apk
)

echo.
echo [3/5] Melakukan commit dengan pesan:
echo "%COMMIT_MSG%"
git commit -m "%COMMIT_MSG%"
if %errorlevel% neq 0 (
    echo [INFO] Tidak ada perubahan baru yang perlu di-commit.
)

:: Push to remote
echo.
echo [4/5] Mendorong ke GitHub (%CURRENT_BRANCH%)...
git push -u origin %CURRENT_BRANCH%

if %errorlevel% neq 0 (
    echo.
    echo [PERINGATAN] Gagal push langsung ke %CURRENT_BRANCH%. Mencoba pull rebase terlebih dahulu...
    git pull origin %CURRENT_BRANCH% --rebase
    echo Mendorong kembali setelah rebase...
    git push -u origin %CURRENT_BRANCH%
)

if %errorlevel% equ 0 (
    echo.
    echo ========================================================
    echo      BERHASIL! Kode telah terdorong ke GitHub:
    echo      %REPO_URL%
    echo ========================================================
) else (
    echo.
    echo ========================================================
    echo  [GAGAL] Terjadi kendala saat push.
    echo  Pastikan Anda telah login/memberikan izin akun GitHub
    echo  (Personal Access Token atau Git Credential Manager).
    echo ========================================================
)

echo.
pause
