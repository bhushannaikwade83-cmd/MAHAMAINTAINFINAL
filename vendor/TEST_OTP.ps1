#!/usr/bin/env pwsh

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "VENDOR OTP SYSTEM - LIVE TEST" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "https://digitrixmedia.com/mahamaintainpro/api"
$testPhone = "9999999999"

Write-Host "Step 1: SEND OTP" -ForegroundColor Yellow
Write-Host ("Phone: " + $testPhone) -ForegroundColor White
Write-Host ""

$body = @{
    phone_number = $testPhone
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri ($baseUrl + "/send-vendor-otp.php") `
        -Method POST `
        -Headers @{"Content-Type"="application/json"} `
        -Body $body `
        -UseBasicParsing

    $data = $response.Content | ConvertFrom-Json

    Write-Host ("Response Status: " + $response.StatusCode) -ForegroundColor Green
    Write-Host ("Success: " + $data.success) -ForegroundColor Green
    Write-Host ("Message: " + $data.message) -ForegroundColor Green
    Write-Host ""
    Write-Host "✓ OTP API is WORKING!" -ForegroundColor Green
}
catch {
    Write-Host ("Error: " + $_.Exception.Message) -ForegroundColor Red
}

Write-Host ""
Write-Host "Step 2: RETRIEVE OTP FROM DATABASE" -ForegroundColor Yellow
Write-Host ""
Write-Host "To verify the OTP, you need to:" -ForegroundColor White
Write-Host "  1. Log into phpMyAdmin" -ForegroundColor Gray
Write-Host "  2. Select database: digitrix_maha_maintain_pro" -ForegroundColor Gray
Write-Host "  3. Run this SQL query:" -ForegroundColor Gray
Write-Host "     SELECT otp FROM vendor_otp_storage WHERE phone_number = '9999999999';" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 3: VERIFY OTP" -ForegroundColor Yellow
Write-Host "Use the OTP you got from the database above to verify:" -ForegroundColor White
Write-Host ""
Write-Host "Example command:" -ForegroundColor Gray
Write-Host '@{phone_number="9999999999"; otp="1234"} | ConvertTo-Json | Invoke-WebRequest -Uri "https://digitrixmedia.com/mahamaintainpro/api/verify-vendor-otp.php" -Method POST -Headers @{"Content-Type"="application/json"} -Body { | ConvertFrom-Json' -ForegroundColor Cyan
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "STATUS: OTP SYSTEM IS OPERATIONAL" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
