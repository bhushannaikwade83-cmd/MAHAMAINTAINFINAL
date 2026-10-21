@echo off
REM Test all vendor OTP APIs
REM Requires curl and a running PHP server (see START_LOCAL_SERVER.bat)

setlocal enabledelayedexpansion

echo.
echo ====================================================
echo Vendor OTP API Test Suite
echo ====================================================
echo.

REM Configuration
set SERVER_URL=http://localhost:8000
set TEST_PHONE=9876543210
set TEST_NAME=John Doe Test Vendor
set TEST_EMAIL=vendor@test.com

echo Testing server at: %SERVER_URL%
echo Test phone: %TEST_PHONE%
echo.

REM Check if curl is available
curl --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: curl is not installed
    echo Please install curl from https://curl.se/download.html
    pause
    exit /b 1
)

echo Checking server connectivity...
curl -s "%SERVER_URL%/send-vendor-otp.php" --max-time 2 >nul
if errorlevel 1 (
    echo ERROR: Cannot connect to %SERVER_URL%
    echo Please make sure the PHP server is running (run START_LOCAL_SERVER.bat)
    pause
    exit /b 1
)
echo Server is reachable!
echo.

REM Test 1: Send OTP
echo Test 1: Send OTP
echo --------------------
echo Sending OTP to %TEST_PHONE%...
for /f "delims=" %%A in ('curl -s -X POST %SERVER_URL%/send-vendor-otp.php -H "Content-Type: application/json" -d {"phone_number": "%TEST_PHONE%"} ^| findstr "success"') do (
    echo Response: %%A
)
echo.
pause

REM Get OTP from database
echo Test 2: Retrieve OTP from Database
echo --------------------
echo Querying database for OTP...
for /f "delims=" %%A in ('mysql -h localhost -u digitrix_maha_user -pmaha_user@70 digitrix_maha_maintain_pro -e "SELECT otp FROM vendor_otp_storage WHERE phone_number = ''%TEST_PHONE%'';" 2^>nul') do (
    if not "%%A"=="otp" (
        set OTP=%%A
        echo Found OTP: %%A
    )
)

if not defined OTP (
    echo ERROR: Could not retrieve OTP from database
    echo Make sure MySQL is running and OTP was sent successfully
    pause
    exit /b 1
)
echo.
pause

REM Test 3: Verify OTP
echo Test 3: Verify OTP
echo --------------------
echo Verifying OTP %OTP%...
curl -s -X POST %SERVER_URL%/verify-vendor-otp.php -H "Content-Type: application/json" -d {"phone_number": "%TEST_PHONE%", "otp": "%OTP%"} | findstr /R "success|exists|token" | head -5
echo.

echo Extracting JWT token from response...
for /f "delims=" %%A in ('curl -s -X POST %SERVER_URL%/verify-vendor-otp.php -H "Content-Type: application/json" -d {"phone_number": "%TEST_PHONE%", "otp": "%OTP%"}') do (
    findstr "token" "%%A" >nul
    if not errorlevel 1 (
        set RESPONSE=%%A
        echo Got response: !RESPONSE!
    )
)
echo.
pause

REM Test 4: Register Vendor (requires token from Test 3)
echo Test 4: Register Vendor (if token available)
echo --------------------
echo This test requires the JWT token from Test 3
echo In production, copy the token from Test 3 response and paste here:
echo.
set /p JWT_TOKEN="Enter JWT Token (or press Enter to skip): "

if not "!JWT_TOKEN!"=="" (
    echo Registering vendor %TEST_NAME%...
    curl -s -X POST %SERVER_URL%/register-vendor.php ^
      -H "Content-Type: application/json" ^
      -H "Authorization: Bearer !JWT_TOKEN!" ^
      -d {"name": "%TEST_NAME%", "email": "%TEST_EMAIL%"} | findstr /R "success|vendor_id|message"
    echo.
) else (
    echo Skipping vendor registration
    echo.
)

REM Test 5: Cleanup
echo Test 5: Cleanup Test Data (Optional)
echo --------------------
set /p CLEANUP="Clean up test data? (y/n): "
if /i "!CLEANUP!"=="y" (
    echo Deleting test data from database...
    mysql -h localhost -u digitrix_maha_user -pmaha_user@70 digitrix_maha_maintain_pro -e "DELETE FROM vendor_otp_storage WHERE phone_number = '%TEST_PHONE%';" 2>nul
    mysql -h localhost -u digitrix_maha_user -pmaha_user@70 digitrix_maha_maintain_pro -e "DELETE FROM vendors WHERE phone = '%TEST_PHONE%';" 2>nul
    echo Test data cleaned up
) else (
    echo Test data retained in database
)
echo.

echo ====================================================
echo Testing Complete!
echo ====================================================
echo.
pause
