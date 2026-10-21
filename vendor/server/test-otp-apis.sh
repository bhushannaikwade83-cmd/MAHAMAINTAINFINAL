#!/bin/bash

# Comprehensive OTP API Testing Script
# Tests all vendor OTP endpoints with proper error handling

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SERVER_URL="${1:-http://localhost:8000}"
TEST_PHONE="9876543210"
TEST_NAME="John Doe Test Vendor"
TEST_EMAIL="vendor@test.com"
DB_HOST="localhost"
DB_USER="digitrix_maha_user"
DB_PASS="maha_user@70"
DB_NAME="digitrix_maha_maintain_pro"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
print_header() {
    echo ""
    echo -e "${BLUE}=================================================="
    echo "$1"
    echo "==================================================${NC}"
    echo ""
}

print_test() {
    echo -e "${BLUE}Test $1: $2${NC}"
    TESTS_RUN=$((TESTS_RUN + 1))
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_debug() {
    echo -e "${YELLOW}  Debug: $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"

    if ! command -v curl &> /dev/null; then
        print_error "curl not found - install with: sudo apt-get install curl"
        exit 1
    fi
    print_success "curl is installed"

    if ! command -v jq &> /dev/null; then
        print_info "jq not found - install with: sudo apt-get install jq (recommended for better JSON parsing)"
    else
        print_success "jq is installed"
    fi

    if ! command -v mysql &> /dev/null; then
        print_info "mysql not found - database queries will be skipped"
    else
        print_success "mysql is installed"
    fi
}

# Check server connectivity
check_server() {
    print_header "Checking Server Connectivity"

    echo "Testing: $SERVER_URL/send-vendor-otp.php"

    local response=$(curl -s -w "\n%{http_code}" "$SERVER_URL/send-vendor-otp.php" 2>/dev/null || true)
    local http_code=$(echo "$response" | tail -1)

    if [ "$http_code" = "200" ] || [ "$http_code" = "400" ]; then
        print_success "Server is reachable (HTTP $http_code)"
    else
        print_error "Server returned HTTP $http_code - ensure PHP server is running"
        exit 1
    fi
}

# Test 1: Send OTP
test_send_otp() {
    print_test "1" "Send OTP"

    local response=$(curl -s -X POST "$SERVER_URL/send-vendor-otp.php" \
        -H "Content-Type: application/json" \
        -d "{\"phone_number\": \"$TEST_PHONE\"}")

    print_debug "Response: $response"

    if echo "$response" | grep -q '"success":true'; then
        print_success "OTP sent successfully"

        # Try to extract requires_mpin field
        if echo "$response" | grep -q '"requires_mpin":true'; then
            print_info "M-PIN is already set for this phone number"
            return 2  # Special return code for M-PIN scenario
        fi
    else
        if echo "$response" | grep -q '"message":"Please wait'; then
            print_error "Resend cooldown active - wait 60 seconds"
        elif echo "$response" | grep -q 'Database connection failed'; then
            print_error "Database connection failed - check MySQL is running"
        else
            print_error "Failed to send OTP: $(echo "$response" | grep -o '"message":"[^"]*' | cut -d'"' -f4)"
        fi
        return 1
    fi
}

# Test 2: Query OTP from Database
test_get_otp_from_db() {
    print_test "2" "Retrieve OTP from Database"

    if ! command -v mysql &> /dev/null; then
        print_info "Skipping - mysql not installed"
        return 0
    fi

    local otp=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -se \
        "SELECT otp FROM vendor_otp_storage WHERE phone_number = '$TEST_PHONE' LIMIT 1;" 2>/dev/null || echo "")

    if [ -z "$otp" ]; then
        print_error "No OTP found in database for $TEST_PHONE"
        return 1
    fi

    print_success "Retrieved OTP from database: $otp"
    echo "$otp"  # Return the OTP
}

# Test 3: Verify OTP
test_verify_otp() {
    print_test "3" "Verify OTP"

    local otp=$1
    if [ -z "$otp" ]; then
        print_info "Skipping - no OTP available"
        return 0
    fi

    local response=$(curl -s -X POST "$SERVER_URL/verify-vendor-otp.php" \
        -H "Content-Type: application/json" \
        -d "{\"phone_number\": \"$TEST_PHONE\", \"otp\": \"$otp\"}")

    print_debug "Response: $(echo "$response" | head -c 200)..."

    if echo "$response" | grep -q '"success":true'; then
        print_success "OTP verified successfully"

        # Extract JWT token
        if command -v jq &> /dev/null; then
            local token=$(echo "$response" | jq -r '.token' 2>/dev/null || echo "")
            if [ ! -z "$token" ]; then
                echo "$token"  # Return the token
            fi
        else
            # Fallback to grep
            local token=$(echo "$response" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
            if [ ! -z "$token" ]; then
                echo "$token"
            fi
        fi
    else
        print_error "Failed to verify OTP: $(echo "$response" | grep -o '"message":"[^"]*' | cut -d'"' -f4)"
        return 1
    fi
}

# Test 4: Register Vendor
test_register_vendor() {
    print_test "4" "Register Vendor"

    local token=$1
    if [ -z "$token" ]; then
        print_info "Skipping - no JWT token available"
        return 0
    fi

    local response=$(curl -s -X POST "$SERVER_URL/register-vendor.php" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $token" \
        -d "{\"name\": \"$TEST_NAME\", \"email\": \"$TEST_EMAIL\"}")

    print_debug "Response: $(echo "$response" | head -c 200)..."

    if echo "$response" | grep -q '"success":true'; then
        print_success "Vendor registered successfully"

        # Extract vendor ID
        local vendor_id=$(echo "$response" | grep -o '"vendor_id":[0-9]*' | cut -d':' -f2)
        if [ ! -z "$vendor_id" ]; then
            print_info "Vendor ID: $vendor_id"
            echo "$vendor_id"
        fi
    else
        print_error "Failed to register vendor: $(echo "$response" | grep -o '"message":"[^"]*' | cut -d'"' -f4)"
        return 1
    fi
}

# Test 5: Wrong OTP
test_wrong_otp() {
    print_test "5" "Wrong OTP Attempt"

    # First, send a fresh OTP
    curl -s -X POST "$SERVER_URL/send-vendor-otp.php" \
        -H "Content-Type: application/json" \
        -d "{\"phone_number\": \"9999999999\"}" > /dev/null

    # Try with wrong OTP
    local response=$(curl -s -X POST "$SERVER_URL/verify-vendor-otp.php" \
        -H "Content-Type: application/json" \
        -d "{\"phone_number\": \"9999999999\", \"otp\": \"0000\"}")

    if echo "$response" | grep -q '"message":"Invalid OTP'; then
        print_success "Wrong OTP correctly rejected"
    else
        print_error "Wrong OTP not handled correctly"
        return 1
    fi
}

# Test 6: Cleanup
test_cleanup() {
    print_test "6" "Cleanup Test Data"

    if ! command -v mysql &> /dev/null; then
        print_info "Skipping - mysql not installed"
        return 0
    fi

    echo "Cleaning up test data..."

    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e \
        "DELETE FROM vendor_otp_storage WHERE phone_number IN ('$TEST_PHONE', '9999999999');" 2>/dev/null || true

    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e \
        "DELETE FROM vendors WHERE phone IN ('$TEST_PHONE', '9999999999');" 2>/dev/null || true

    print_success "Test data cleaned up"
}

# Main execution
main() {
    print_header "Vendor OTP API Test Suite"
    echo "Server: $SERVER_URL"
    echo "Test Phone: $TEST_PHONE"
    echo ""

    check_prerequisites
    check_server

    echo ""
    echo "Running tests..."
    echo ""

    # Run tests
    test_send_otp || true
    otp=$(test_get_otp_from_db || true)
    test_verify_otp "$otp" || true
    token=$(test_verify_otp "$otp" 2>/dev/null || true)
    test_register_vendor "$token" || true
    test_wrong_otp || true
    test_cleanup || true

    # Summary
    print_header "Test Summary"
    echo "Total tests: $TESTS_RUN"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed. Check output above for details.${NC}"
        return 1
    fi
}

# Run main function
main "$@"
