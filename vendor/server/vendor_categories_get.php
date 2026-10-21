<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';
set_cors_headers();
header('Content-Type: application/json');

require_once __DIR__ . '/jwt-auth.php';

try {
    $vendorToken = requireVendorRole();
    $vendorId = (string) $vendorToken['vendor_id'];

    $stmt = db()->prepare('SELECT category_id FROM vendor_service_categories WHERE vendor_id = ?');
    $stmt->execute([$vendorId]);
    $categoryIds = array_map(fn($row) => (int)$row['category_id'], $stmt->fetchAll());

    json_response(['category_ids' => $categoryIds]);
} catch (Exception $e) {
    http_response_code(500);
    json_response(['success' => false, 'error' => 'Failed to load categories: ' . $e->getMessage()]);
}
