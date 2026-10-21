@echo off
REM Start PHP built-in web server for local testing
REM This allows testing the OTP APIs without needing a live server

echo.
echo ====================================================
echo Vendor App OTP API - Local Testing Server
echo ====================================================
echo.

REM Check if PHP is installed
php -v >nul 2>&1
if errorlevel 1 (
    echo ERROR: PHP is not installed or not in PATH
    echo Please install PHP from https://www.php.net/downloads
    pause
    exit /b 1
)

echo PHP version:
php -v | findstr /R "^PHP"
echo.

REM Check if MySQL is running
mysql -h localhost -u digitrix_maha_user -pmaha_user@70 -e "SELECT VERSION();" >nul 2>&1
if errorlevel 1 (
    echo WARNING: Cannot connect to MySQL database
    echo Make sure MySQL is running with these credentials:
    echo   Host: localhost
    echo   User: digitrix_maha_user
    echo   Password: maha_user@70
    echo   Database: digitrix_maha_maintain_pro
    echo.
    echo The server will start anyway, but API calls will fail without database
    echo.
    pause
) else (
    echo Database connection OK
    echo.
)

REM Start the server
cd /d "%~dp0"
echo Starting server on http://localhost:8000
echo.
echo Test endpoints:
echo   - http://localhost:8000/send-vendor-otp.php
echo   - http://localhost:8000/verify-vendor-otp.php
echo   - http://localhost:8000/register-vendor.php
echo.
echo Press Ctrl+C to stop the server
echo.

php -S localhost:8000

pause
