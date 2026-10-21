<?php
header('Content-Type: application/json');

$phone = $_GET['phone'] ?? $_POST['phone'] ?? '9999999999';

try {
    $pdo = new PDO(
        'mysql:host=localhost;dbname=digitrix_maha_maintain_pro',
        'digitrix_maha_user',
        'maha_user@70'
    );

    $stmt = $pdo->prepare("SELECT otp, expires_at FROM vendor_otp_storage WHERE phone_number = ? LIMIT 1");
    $stmt->execute([$phone]);

    if ($stmt->rowCount() > 0) {
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        echo json_encode([
            'success' => true,
            'otp' => $row['otp'],
            'phone' => $phone,
            'expires_at' => $row['expires_at']
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'No OTP found for this phone number',
            'phone' => $phone
        ]);
    }
} catch (PDOException $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Database connection failed: ' . $e->getMessage()
    ]);
}
?>
