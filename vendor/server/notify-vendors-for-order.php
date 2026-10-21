<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';
set_cors_headers();

header('Content-Type: application/json');

// This endpoint is called when a new order is created
// It notifies all vendors who provide that service category

try {
    $input = json_decode((string)file_get_contents('php://input'), true);

    $orderId = $input['order_id'] ?? null;
    $categoryId = $input['category_id'] ?? null;
    $customerId = $input['customer_id'] ?? null;
    $amount = $input['amount'] ?? 0;
    $pincode = $input['pincode'] ?? null;
    $serviceType = $input['service_type'] ?? null;

    if (!$orderId || !$categoryId) {
        json_response(['error' => 'order_id and category_id are required'], 400);
    }

    // Find all vendors who serve this category and have registered this pincode
    $stmt = db()->prepare(
        'SELECT DISTINCT v.id, v.phone_number, v.device_token
         FROM vendors v
         INNER JOIN vendor_service_categories vsc ON vsc.vendor_id = v.id
         INNER JOIN vendor_pincodes vp ON vp.vendor_id = v.id
         WHERE vsc.category_id = ?
           AND vp.pincode = ?
           AND v.is_online = 1
         LIMIT 10'
    );
    $stmt->execute([$categoryId, $pincode]);
    $vendors = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Store notifications for each vendor
    $notificationCount = 0;
    foreach ($vendors as $vendor) {
        $notifStmt = db()->prepare(
            'INSERT INTO notifications (phone_number, title, body, type, reference_id, created_at)
             VALUES (?, ?, ?, ?, ?, NOW())'
        );

        $title = 'New Job Request - ' . $serviceType;
        $body = "New order ORD$orderId for $serviceType in pincode $pincode. Amount: ₹$amount";

        $notifStmt->execute([
            $vendor['phone_number'],
            $title,
            $body,
            'order',
            $orderId
        ]);
        $notificationCount++;

        // TODO: Send push notification via Firebase Cloud Messaging
        // if ($vendor['device_token']) {
        //     sendFCMNotification($vendor['device_token'], $title, $body);
        // }
    }

    json_response([
        'success' => true,
        'message' => "Order notification sent to $notificationCount vendors",
        'vendors_notified' => count($vendors),
    ]);

} catch (Exception $e) {
    http_response_code(500);
    json_response(['success' => false, 'error' => 'Failed to notify vendors: ' . $e->getMessage()]);
}
