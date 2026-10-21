<?php
/**
 * Vendor OTP System - Database Setup Script
 * This script creates all required database tables for the vendor app
 */

echo "================================================\n";
echo "Vendor OTP Database Setup\n";
echo "================================================\n\n";

$servername = "localhost";
$username = "digitrix_maha_user";
$password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

// Connect to database
echo "Connecting to database: $database...\n";
$conn = new mysqli($servername, $username, $password, $database);

if ($conn->connect_error) {
    echo "❌ Connection failed: " . $conn->connect_error . "\n";
    exit(1);
}

echo "✓ Database connected\n\n";

// SQL statements to execute
$sqls = [
    "vendors" => "CREATE TABLE IF NOT EXISTS vendors (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) DEFAULT NULL,
        phone VARCHAR(10) NOT NULL,
        email VARCHAR(255) DEFAULT NULL,
        status VARCHAR(20) NOT NULL DEFAULT 'pending',
        mpin_hash VARCHAR(255) NULL,
        mpin_attempts INT NOT NULL DEFAULT 0,
        mpin_locked_until DATETIME NULL,
        is_online TINYINT(1) DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY uq_vendor_phone (phone)
    )",

    "vendor_otp_storage" => "CREATE TABLE IF NOT EXISTS vendor_otp_storage (
        id INT AUTO_INCREMENT PRIMARY KEY,
        phone_number VARCHAR(10) NOT NULL,
        otp VARCHAR(4) NOT NULL,
        attempts INT NOT NULL DEFAULT 0,
        expires_at DATETIME NOT NULL,
        created_at DATETIME NOT NULL,
        UNIQUE KEY uq_vendor_otp_phone (phone_number)
    )",

    "service_categories" => "CREATE TABLE IF NOT EXISTS service_categories (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        icon VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )",

    "vendor_service_categories" => "CREATE TABLE IF NOT EXISTS vendor_service_categories (
        id INT AUTO_INCREMENT PRIMARY KEY,
        vendor_id INT NOT NULL,
        category_id INT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uq_vendor_category (vendor_id, category_id),
        FOREIGN KEY (vendor_id) REFERENCES vendors(id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES service_categories(id) ON DELETE CASCADE
    )",

    "vendor_pincodes" => "CREATE TABLE IF NOT EXISTS vendor_pincodes (
        id INT AUTO_INCREMENT PRIMARY KEY,
        vendor_id INT NOT NULL,
        pincode VARCHAR(6) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uq_vendor_pincode (vendor_id, pincode),
        KEY idx_vendor_id (vendor_id),
        FOREIGN KEY (vendor_id) REFERENCES vendors(id) ON DELETE CASCADE
    )",

    "bookings" => "CREATE TABLE IF NOT EXISTS bookings (
        id INT AUTO_INCREMENT PRIMARY KEY,
        customer_name VARCHAR(255) NOT NULL,
        customer_phone VARCHAR(10) NOT NULL,
        category_id INT NOT NULL,
        service_type VARCHAR(255),
        notes TEXT,
        address TEXT,
        pincode VARCHAR(6),
        latitude DECIMAL(10, 8),
        longitude DECIMAL(11, 8),
        amount DECIMAL(10, 2) NOT NULL,
        payment_mode VARCHAR(50),
        scheduled_at DATETIME,
        vendor_id INT,
        status VARCHAR(50) NOT NULL DEFAULT 'REQUESTED',
        before_photo_path VARCHAR(255),
        after_photo_path VARCHAR(255),
        rating INT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        accepted_at DATETIME,
        started_at DATETIME,
        completed_at DATETIME,
        KEY idx_vendor_id (vendor_id),
        KEY idx_category_id (category_id),
        KEY idx_status (status),
        FOREIGN KEY (vendor_id) REFERENCES vendors(id) ON DELETE SET NULL,
        FOREIGN KEY (category_id) REFERENCES service_categories(id) ON DELETE RESTRICT
    )",

    "booking_rejections" => "CREATE TABLE IF NOT EXISTS booking_rejections (
        id INT AUTO_INCREMENT PRIMARY KEY,
        booking_id INT NOT NULL,
        vendor_id INT NOT NULL,
        reason VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uq_vendor_booking (vendor_id, booking_id),
        FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
        FOREIGN KEY (vendor_id) REFERENCES vendors(id) ON DELETE CASCADE
    )"
];

// Execute create table statements
foreach ($sqls as $table => $sql) {
    echo "Creating table: $table...\n";
    if ($conn->query($sql) === TRUE) {
        echo "  ✓ $table table ready\n";
    } else {
        echo "  ❌ Error: " . $conn->error . "\n";
        exit(1);
    }
}

echo "\n================================================\n";
echo "✓ Database setup complete!\n";
echo "================================================\n\n";

// Verify tables exist
echo "Verifying tables...\n";
$tables_result = $conn->query("SHOW TABLES LIKE 'vendor%'");
if ($tables_result) {
    echo "Tables found:\n";
    while ($row = $tables_result->fetch_row()) {
        echo "  ✓ " . $row[0] . "\n";
    }
} else {
    echo "❌ Could not verify tables: " . $conn->error . "\n";
}

echo "\nDatabase is ready for vendor OTP system!\n";

$conn->close();
?>
