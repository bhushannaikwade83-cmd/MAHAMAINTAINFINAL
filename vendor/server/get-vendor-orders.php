<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';
set_cors_headers();

header('Content-Type: application/json');

require_once __DIR__ . '/jwt-auth.php';

try {
    $vendorToken = requireVendorRole();
    $vendorId = (int) $vendorToken['vendor_id'];

    // Fetch vendor's service pincodes
    $pincodeStmt = db()->prepare(
        'SELECT pincode FROM vendor_pincodes WHERE vendor_id = ? ORDER BY pincode'
    );
    $pincodeStmt->execute([$vendorId]);
    $vendorPincodes = $pincodeStmt->fetchAll(PDO::FETCH_COLUMN);

    // Fetch orders that contain items from this vendor
    $stmt = db()->prepare(
        'SELECT DISTINCT o.* FROM orders o
         JOIN carts c ON c.cart_id = o.cart_id
         JOIN cart_items ci ON ci.cart_id = c.cart_id
         WHERE ci.provider_id = ?
         ORDER BY o.created_at DESC'
    );
    $stmt->execute([$vendorId]);
    $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $formattedOrders = [];
    foreach ($orders as $order) {
        $orderPincode = $order['pincode'] ?? null;
        $isPincodeMatch = $orderPincode && in_array($orderPincode, $vendorPincodes);

        $formattedOrders[] = [
            'id' => (int)$order['id'],
            'order_id' => $order['order_id'],
            'cart_id' => $order['cart_id'],
            'user_id' => $order['user_id'],
            'pincode' => $orderPincode,
            'pincode_matches' => $isPincodeMatch,
            'vendor_pincodes' => $vendorPincodes,
            'total_amount' => (float)$order['total_amount'],
            'discount_amount' => (float)$order['discount_amount'],
            'coupon_code' => $order['coupon_code'],
            'service_count' => (int)$order['service_count'],
            'scheduled_at' => $order['scheduled_at'],
            'payment_method' => $order['payment_method'],
            'payment_status' => $order['payment_status'],
            'order_status' => $order['order_status'],
            'created_at' => $order['created_at'],
        ];
    }

    json_response([
        'success' => true,
        'orders' => $formattedOrders,
        'vendor_pincodes' => $vendorPincodes,
        'count' => count($formattedOrders),
    ]);
} catch (Exception $e) {
    http_response_code(500);
    json_response(['success' => false, 'error' => 'Failed to load orders: ' . $e->getMessage()]);
}
