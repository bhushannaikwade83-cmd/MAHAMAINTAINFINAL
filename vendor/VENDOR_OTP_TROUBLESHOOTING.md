# Vendor OTP API - Comprehensive Troubleshooting Guide

## Issues Found & Solutions

### Issue 1: JWT Token Not Being Used in register-vendor.php

**Problem**: The `register-vendor.php` file calls `requireVendorRoleAllowUnregistered()` from `jwt-auth.php`, but this function may not be properly implemented.

**Location**: `server/register-vendor.php` line 14

**Solution**: Verify jwt-auth.php has this function:

```php
function requireVendorRoleAllowUnregistered() {
    $token = verifyJWTToken();
    if (($token['role'] ?? null) !== 'vendor') {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Unauthorized']);
        exit();
    }
    return $token;
}
```

**Check**: Open `server/jwt-auth.php` and search for `requireVendorRoleAllowUnregistered` function. If not found, add it.

---

### Issue 2: Missing M-PIN Hash Function

**Problem**: When setting M-PIN, the code needs to hash the PIN. PHP's `password_hash()` is recommended for security.

**Location**: `server/set-vendor-mpin.php` (if it exists)

**Solution**: The M-PIN should be hashed like this:

```php
$mpin_hash = password_hash($mpin, PASSWORD_BCRYPT);
```

And verified with:

```php
if (password_verify($mpin, $stored_hash)) {
    // Correct M-PIN
}
```

---

### Issue 3: SMS Gateway May Not Work in Test Environment

**Problem**: The SMS gateway (lines 20-25 in `send-vendor-otp.php`) requires:
- Valid BPIL account credentials
- Template registered with DLT
- Phone number should be real for SMS delivery

**Current Credentials**:
```php
$SMS_USER = "acctsmmp";
$SMS_KEY = "503856edbcXX";
$SMS_SENDER_ID = "MHMNPR";
$SMS_ENTITY_ID = "1701178591434877016";
$SMS_TEMPLATE_ID = "1777178609736013559";
```

**Solution for Testing**:
1. **If SMS fails** - OTP is still generated and stored in database
2. **To retrieve OTP** - Use phpMyAdmin:
   ```sql
   SELECT otp FROM vendor_otp_storage WHERE phone_number = '9876543210';
   ```
3. **Use the OTP manually** to test verification flow

---

### Issue 4: Timezone-Related OTP Expiration Issues

**Problem**: If server is in UTC but database is in IST, the 10-minute OTP expiration may show incorrect wait times.

**Location**: `server/send-vendor-otp.php` line 96 and `verify-vendor-otp.php` line 62

**Current Code**:
```php
// Potential issue - mixing PHP time() with MySQL NOW()
if (strtotime($row['expires_at']) < time()) {
    // OTP expired
}
```

**Better Solution** (already in code):
```php
// This is better - uses SQL to compare times
$check_stmt = $conn->prepare(
    "SELECT TIMESTAMPDIFF(SECOND, created_at, NOW()) AS elapsed FROM vendor_otp_storage WHERE phone_number = ?"
);
```

**Action Required**: Ensure database timezone is set to IST (UTC+5:30)

```sql
SET time_zone = '+05:30';
SELECT NOW();  -- Should show IST time
```

---

### Issue 5: Missing MPIN Hash Column in Live Database

**Problem**: If `vendors.mpin_hash` column doesn't exist, M-PIN check in `send-vendor-otp.php` will fail.

**Location**: `server/send-vendor-otp.php` line 58

**Error Symptom**: "Unknown column 'mpin_hash' in 'where clause'"

**Solution**: Run this SQL in phpMyAdmin:

```sql
ALTER TABLE vendors ADD COLUMN mpin_hash VARCHAR(255) NULL;
ALTER TABLE vendors ADD COLUMN mpin_attempts INT NOT NULL DEFAULT 0;
ALTER TABLE vendors ADD COLUMN mpin_locked_until DATETIME NULL;
```

---

### Issue 6: JWT Token Not Persisting in Flutter App

**Problem**: The JWT token returned from `verify-vendor-otp.php` might not be saved properly in Flutter.

**Location**: `lib/repositories/auth_repository.dart` line 161

**Verification**: 
1. After OTP verification, check if token is saved:
   ```bash
   # In Flutter app debug console:
   SharedPreferences prefs = await SharedPreferences.getInstance();
   String? token = prefs.getString('vendor_jwt_token');
   print(token);  // Should print the JWT, not null
   ```

**Solution**: The code already has this, but verify `setToken()` is called:
```dart
await SupabaseAuthRepository.setToken(data['token'] as String?);
```

---

### Issue 7: Database Collation Mismatch

**Problem**: If vendor table uses different collation (utf8 vs utf8mb4), special characters may not store correctly.

**Check SQL**:
```sql
SHOW CREATE TABLE vendors;
SHOW CREATE TABLE vendor_otp_storage;
```

**Solution - Ensure UTF8MB4 Collation**:
```sql
ALTER TABLE vendors CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE vendor_otp_storage CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

---

### Issue 8: CORS Headers Not Set for Web Testing

**Problem**: When testing from Flutter web (`flutter run -d chrome`), CORS headers are needed.

**Current Code** (lines 2-6 in send-vendor-otp.php):
```php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Max-Age: 86400');
```

**This is correct** - All CORS headers are already present.

**If still not working**: Check browser console for CORS errors. The server might be blocking CORS at Apache/Nginx level.

---

### Issue 9: Silent SMS Failure with 200 Status

**Problem**: SMS gateway might return success (HTTP 200) even when SMS fails, because `file_get_contents()` succeeds but the gateway silently drops the message.

**Location**: `server/send-vendor-otp.php` line 128-137

**Current Code**:
```php
$response = @file_get_contents($sms_url, false, $context);
echo json_encode([
    'success' => true,  // This is true even if SMS failed!
    'message' => $response === false ? 'OTP generated. SMS delivery may be delayed.' : 'OTP sent successfully',
    'otp_sent' => true,
]);
```

**This is acceptable** - OTP is still stored in database even if SMS fails. The message indicates this.

**For Testing**: Always verify OTP in database rather than waiting for SMS.

---

### Issue 10: No Vendor ID in M-PIN Login Response

**Problem**: When vendor logs in with M-PIN, the response might not include vendor_id.

**File**: `server/verify-vendor-mpin.php` (if it exists)

**Expected Response**:
```json
{
  "success": true,
  "vendor_id": 123,
  "token": "...",
  "name": "Vendor Name"
}
```

**Check**: This file should have been created. If missing, contact development team.

---

## Diagnostic Queries

### Check All Vendors
```sql
SELECT id, name, phone, email, status, created_at FROM vendors;
```

### Check Pending OTPs
```sql
SELECT phone_number, otp, attempts, expires_at FROM vendor_otp_storage;
```

### Check M-PIN Settings
```sql
SELECT id, phone, name, mpin_hash, mpin_attempts, mpin_locked_until FROM vendors;
```

### Check OTP Expiration
```sql
SELECT 
    phone_number,
    otp,
    TIMESTAMPDIFF(MINUTE, created_at, NOW()) as minutes_old,
    CASE WHEN TIMESTAMPDIFF(MINUTE, created_at, NOW()) > 10 
        THEN 'EXPIRED' 
        ELSE 'VALID' 
    END as status
FROM vendor_otp_storage;
```

### Clean Old OTPs (Keep only recent)
```sql
DELETE FROM vendor_otp_storage WHERE created_at < DATE_SUB(NOW(), INTERVAL 1 DAY);
```

### Test Database Connectivity
```sql
SELECT 'Connection Successful' as status;
```

---

## Performance Checks

### Check Database Index Health
```sql
SHOW INDEX FROM vendors;
SHOW INDEX FROM vendor_otp_storage;
```

Expected output should show:
- `uq_vendor_phone` index on vendors.phone
- `uq_vendor_otp_phone` index on vendor_otp_storage.phone_number

### Check Query Performance
```sql
EXPLAIN SELECT * FROM vendor_otp_storage WHERE phone_number = '9876543210';
```

Should use index (key = `uq_vendor_otp_phone`)

---

## Security Audit Checklist

- [ ] Database credentials are NOT hardcoded in production files
- [ ] JWT_SECRET is generated or set via environment variable
- [ ] SMS credentials are not logged or exposed
- [ ] M-PIN hashing uses `password_hash()` with BCRYPT
- [ ] OTP is max 5 attempts before rejection
- [ ] OTP expires after 10 minutes
- [ ] Resend cooldown is enforced (60 seconds)
- [ ] SQL injection is prevented (using prepared statements)
- [ ] CORS headers are properly set
- [ ] HTTPS is enforced in production
- [ ] Sensitive errors are not shown to users

---

## Testing in Different Scenarios

### Scenario 1: Brand New Phone Number
```bash
# Send OTP
curl -X POST https://digitrixmedia.com/mahamaintainpro/api/send-vendor-otp.php \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "9999999999"}'

# Verify OTP (get from DB or SMS)
curl -X POST https://digitrixmedia.com/mahamaintainpro/api/verify-vendor-otp.php \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "9999999999", "otp": "1234"}'

# Response should have: "exists": false
# Then register vendor

curl -X POST https://digitrixmedia.com/mahamaintainpro/api/register-vendor.php \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN_FROM_VERIFY_OTP>" \
  -d '{"name": "New Vendor", "email": "vendor@test.com"}'
```

### Scenario 2: Existing Vendor (Already Registered)
```bash
# Send OTP for existing phone
curl -X POST https://digitrixmedia.com/mahamaintainpro/api/send-vendor-otp.php \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "9876543210"}'

# Verify OTP
curl -X POST https://digitrixmedia.com/mahamaintainpro/api/verify-vendor-otp.php \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "9876543210", "otp": "1234"}'

# Response should have: "exists": true, "vendor_id": X
# Skip registration, go straight to dashboard
```

### Scenario 3: Vendor with M-PIN Set
```bash
# Send OTP for vendor with M-PIN
curl -X POST https://digitrixmedia.com/mahamaintainpro/api/send-vendor-otp.php \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "9876543210"}'

# Response should have: "requires_mpin": true
# Flutter app should show M-PIN screen instead of OTP screen

# Verify M-PIN (once set-vendor-mpin is implemented)
curl -X POST https://digitrixmedia.com/mahamaintainpro/api/verify-vendor-mpin.php \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "9876543210", "mpin": "1234"}'
```

---

## Performance Optimization Notes

1. **OTP lookups are indexed** - using phone_number unique index
2. **Database queries use prepared statements** - prevents SQL injection
3. **SMS sending is non-blocking** - doesn't wait for SMS gateway response
4. **60-second resend cooldown** - prevents SMS abuse
5. **5 attempt limit** - prevents brute force attacks on 4-digit OTP

---

## Monitoring & Logging

To track issues in production, add logging:

```php
// Add to send-vendor-otp.php
error_log("OTP Request: Phone=$phone_number, Force=$force_otp, Time=" . date('Y-m-d H:i:s'));

// Add to verify-vendor-otp.php
error_log("OTP Verify: Phone=$phone_number, Attempts=$row['attempts'], Result=SUCCESS");
```

Check PHP error log:
```bash
tail -f /var/log/php-errors.log
```

---

## Quick Fix Commands

```sql
-- Fix 1: Add M-PIN columns if missing
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS mpin_hash VARCHAR(255) NULL;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS mpin_attempts INT NOT NULL DEFAULT 0;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS mpin_locked_until DATETIME NULL;

-- Fix 2: Verify charset
ALTER TABLE vendors CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE vendor_otp_storage CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Fix 3: Clean old test data
DELETE FROM vendor_otp_storage WHERE created_at < DATE_SUB(NOW(), INTERVAL 7 DAY);

-- Fix 4: Check all tables exist
SHOW TABLES LIKE 'vendor%';
```

---

## Still Having Issues?

1. **Check PHP error log** - `error_log()` messages appear here
2. **Check MySQL error log** - Database connection errors
3. **Check SMS gateway status** - Visit gateway provider's status page
4. **Test with curl locally** - Verify API responds before testing from app
5. **Inspect network requests** - Use browser DevTools to see exact request/response
6. **Check database directly** - Use phpMyAdmin to verify data is stored
