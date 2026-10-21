#!/bin/bash

# Vendor OTP Database Setup Script
# Runs the required SQL migrations to set up the vendor app backend

set -e  # Exit on error

DB_HOST="localhost"
DB_USER="digitrix_maha_user"
DB_PASS="maha_user@70"
DB_NAME="digitrix_maha_maintain_pro"

echo "=================================================="
echo "Vendor App - Database Setup"
echo "=================================================="
echo ""
echo "Database: $DB_NAME"
echo "Host: $DB_HOST"
echo "User: $DB_USER"
echo ""

# Check if MySQL is available
if ! command -v mysql &> /dev/null; then
    echo "ERROR: mysql command not found"
    echo "Please install MySQL client: sudo apt-get install mysql-client"
    exit 1
fi

# Test connection
echo "Testing database connection..."
if ! mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "SELECT 1;" &> /dev/null; then
    echo "ERROR: Cannot connect to database"
    echo "Check credentials:"
    echo "  Host: $DB_HOST"
    echo "  User: $DB_USER"
    echo "  Password: $DB_PASS"
    exit 1
fi
echo "✓ Database connection successful"
echo ""

# Function to run SQL file
run_sql() {
    local file=$1
    local description=$2

    if [ ! -f "$file" ]; then
        echo "ERROR: SQL file not found: $file"
        return 1
    fi

    echo "Running: $description"
    echo "  File: $file"

    if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$file" 2>&1; then
        echo "  ✓ Success"
    else
        echo "  ✗ Failed"
        return 1
    fi
    echo ""
}

# Run migrations
echo "Running SQL migrations..."
echo ""

# Core vendor tables (REQUIRED)
run_sql "create-vendor-tables.sql" "Create vendor OTP tables" || true

# KYC verification tables (REQUIRED)
run_sql "schema.sql" "Create KYC verification tables" || true

# M-PIN support (OPTIONAL)
run_sql "add-vendor-mpin.sql" "Add M-PIN support" || true

# Booking system (RECOMMENDED)
run_sql "bookings-schema.sql" "Create booking/job system tables" || true

# Society directory (OPTIONAL)
run_sql "societies-schema.sql" "Create society directory" || true

# Online status (OPTIONAL)
run_sql "add-vendor-online-status.sql" "Add online status tracking" || true

echo ""
echo "=================================================="
echo "Database Setup Complete!"
echo "=================================================="
echo ""
echo "Verification:"
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
    SELECT
        COUNT(*) as table_count
    FROM information_schema.tables
    WHERE table_schema = '$DB_NAME'
    AND table_name LIKE 'vendor%'
        OR table_name = 'booking%'
        OR table_name = 'digilocker%';
" 2>/dev/null || echo "Could not verify tables"

echo ""
echo "Next steps:"
echo "1. Start PHP server: php -S localhost:8000"
echo "2. Run tests: bash test-otp-apis.sh"
echo "3. Deploy files to production: https://digitrixmedia.com/mahamaintainpro/api/"
echo ""
