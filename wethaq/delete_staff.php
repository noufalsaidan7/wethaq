<?php
header('Content-Type: application/json; charset=utf-8');

$mysqli = @new mysqli('127.0.0.1', 'root', '', 'wethaq_db');
if ($mysqli->connect_errno) {
    http_response_code(500);
    echo json_encode(['status'=>'error','message'=>'DB connect failed: '.$mysqli->connect_error]);
    exit;
}
$mysqli->set_charset('utf8mb4');

$userId = intval($_POST['user_id'] ?? 0);
if ($userId <= 0) {
    http_response_code(400);
    echo json_encode(['status'=>'error','message'=>'user_id required']);
    exit;
}

$stmt = $mysqli->prepare("DELETE FROM users WHERE id=? AND role='Staff'");
$stmt->bind_param('i', $userId);
if (!$stmt->execute()) {
    http_response_code(500);
    echo json_encode(['status'=>'error','message'=>'Delete failed: '.$stmt->error]);
    exit;
}
$stmt->close();

echo json_encode(['status'=>'success','message'=>'Staff deleted']);
?>
