<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';
set_cors_headers();

header('Content-Type: application/json');

try {
    $input = json_decode((string)file_get_contents('php://input'), true);

    $orderId = $input['order_id'] ?? null;

    if (!$orderId) {
        json_response(['error' => 'order_id is required'], 400);
    }

    // Get category_id and service details from order
    $stmt = db()->prepare(
        'SELECT o.id, o.order_id, o.category_id, o.service_type, o.pincode, o.total_amount,
                sc.name as category_name, o.customer_name, o.customer_phone
         FROM orders o
         LEFT JOIN service_categories sc ON sc.id = o.category_id
         WHERE o.order_id = ? OR o.id = ?
         LIMIT 1'
    );
    $stmt->execute([$orderId, $orderId]);
    $order = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$order) {
        json_response(['error' => 'Order not found'], 404);
    }

    json_response([
        'success' => true,
        'order' => [
            'id' => (int)$order['id'],
            'order_id' => $order['order_id'],
            'category_id' => (int)$order['category_id'],
            'category_name' => $order['category_name'],
            'service_type' => $order['service_type'],
            'pincode' => $order['pincode'],
            'total_amount' => (float)$order['total_amount'],
            'customer_name' => $order['customer_name'],
            'customer_phone' => $order['customer_phone'],
        ]
    ]);

} catch (Exception $e) {
    http_response_code(500);
    json_response(['success' => false, 'error' => 'Failed to get order category: ' . $e->getMessage()]);
}
