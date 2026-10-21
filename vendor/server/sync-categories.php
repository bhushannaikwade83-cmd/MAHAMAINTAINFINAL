<?php
declare(strict_types=1);

require __DIR__ . '/vendor_config.php';
set_cors_headers();

header('Content-Type: application/json');

try {
    $categories = [
        'Insta Help',
        'Women\'s Salon & Spa',
        'Men\'s Salon & Massage',
        'Cleaning',
        'Home Painting',
        'AC & Appliance Repair',
        'Electrician, Plumber & Carpenter',
        'Vehicle Care',
        'Food & Catering',
        'Health & Care',
        'Pooja Services',
        'Festival Services',
        'Pest Control',
        'Smart Society Management',
        'Real Estate',
        'Interior Designer',
        'Hologram Services',
        'Fire Safety',
        'Water Proofing',
        'Water Testing',
        'Blood Testing',
        'Weekly Bazar',
        'Tours & Travels',
    ];

    $pdo = db();
    $pdo->beginTransaction();

    $stmt = $pdo->prepare(
        'INSERT IGNORE INTO service_categories (name, is_active, created_at)
         VALUES (?, 1, NOW())'
    );

    $inserted = 0;
    foreach ($categories as $name) {
        if ($stmt->execute([$name])) {
            if ($stmt->rowCount() > 0) {
                $inserted++;
            }
        }
    }

    $updateStmt = $pdo->prepare(
        'UPDATE service_categories SET is_active = 1 WHERE name = ?'
    );
    $updated = 0;
    foreach ($categories as $name) {
        $updateStmt->execute([$name]);
        $updated += $updateStmt->rowCount();
    }

    $pdo->commit();

    json_response([
        'success' => true,
        'message' => "Categories synced: $inserted new, $updated updated",
        'total_categories' => count($categories),
    ]);

} catch (Exception $e) {
    http_response_code(500);
    json_response(['success' => false, 'error' => 'Sync failed: ' . $e->getMessage()]);
}
