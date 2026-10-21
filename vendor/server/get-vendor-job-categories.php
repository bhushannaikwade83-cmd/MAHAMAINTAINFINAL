<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';
set_cors_headers();

header('Content-Type: application/json');

require_once __DIR__ . '/jwt-auth.php';

try {
    $vendorToken = requireVendorRole();
    $vendorId = (string) $vendorToken['vendor_id'];

    // Get vendor's selected service categories with job counts
    $stmt = db()->prepare(
        'SELECT
            sc.id,
            sc.name,
            sc.description,
            COUNT(b.id) as job_count
         FROM service_categories sc
         INNER JOIN vendor_service_categories vsc ON vsc.category_id = sc.id
         LEFT JOIN bookings b ON b.category_id = sc.id
            AND b.status = "REQUESTED"
            AND b.vendor_id IS NULL
            AND b.id NOT IN (
                SELECT booking_id FROM booking_rejections WHERE vendor_id = ?
            )
         WHERE vsc.vendor_id = ? AND sc.is_active = 1
         GROUP BY sc.id, sc.name, sc.description
         ORDER BY sc.name ASC'
    );
    $stmt->execute([$vendorId, $vendorId]);
    $categories = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $formattedCategories = [];
    foreach ($categories as $cat) {
        $formattedCategories[] = [
            'id' => (int)$cat['id'],
            'name' => $cat['name'],
            'description' => $cat['description'],
            'job_count' => (int)$cat['job_count'],
        ];
    }

    json_response([
        'success' => true,
        'categories' => $formattedCategories,
        'total_jobs' => array_sum(array_column($formattedCategories, 'job_count')),
    ]);
} catch (Exception $e) {
    http_response_code(500);
    json_response(['success' => false, 'error' => 'Failed to load categories: ' . $e->getMessage()]);
}
