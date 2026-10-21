<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';
set_cors_headers();

header('Content-Type: application/json');

require_once __DIR__ . '/jwt-auth.php';

try {
    $vendorToken = requireVendorRole();
    $vendorId = (string) $vendorToken['vendor_id'];

    // Get vendor's selected service categories
    $categoriesStmt = db()->prepare(
        'SELECT category_id FROM vendor_service_categories WHERE vendor_id = ?'
    );
    $categoriesStmt->execute([$vendorId]);
    $vendorCategories = array_map(fn($row) => $row['category_id'], $categoriesStmt->fetchAll(PDO::FETCH_ASSOC));

    if (empty($vendorCategories)) {
        json_response([
            'success' => true,
            'categories' => [],
            'orders_by_category' => [],
            'message' => 'No service categories selected'
        ]);
        return;
    }

    // Get orders for vendor's categories with job counts
    $placeholders = implode(',', array_fill(0, count($vendorCategories), '?'));
    $stmt = db()->prepare(
        "SELECT
            sc.id,
            sc.name,
            COUNT(o.id) as order_count,
            SUM(CASE WHEN o.current_status = 'requested' THEN 1 ELSE 0 END) as pending_orders,
            SUM(CASE WHEN o.current_status = 'accepted' THEN 1 ELSE 0 END) as accepted_orders
         FROM service_categories sc
         LEFT JOIN orders o ON o.category_id = sc.id
            AND o.current_status IN ('requested', 'accepted')
         WHERE sc.id IN ($placeholders) AND sc.is_active = 1
         GROUP BY sc.id, sc.name
         ORDER BY pending_orders DESC, sc.name ASC"
    );
    $stmt->execute($vendorCategories);
    $categories = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Format response
    $formattedCategories = [];
    $totalOrders = 0;
    foreach ($categories as $cat) {
        $orderCount = (int)$cat['order_count'];
        $totalOrders += $orderCount;
        $formattedCategories[] = [
            'id' => (int)$cat['id'],
            'name' => $cat['name'],
            'total_orders' => $orderCount,
            'pending_orders' => (int)($cat['pending_orders'] ?? 0),
            'accepted_orders' => (int)($cat['accepted_orders'] ?? 0),
        ];
    }

    json_response([
        'success' => true,
        'categories' => $formattedCategories,
        'total_new_orders' => $totalOrders,
    ]);
} catch (Exception $e) {
    http_response_code(500);
    json_response(['success' => false, 'error' => 'Failed to load orders by category: ' . $e->getMessage()]);
}
