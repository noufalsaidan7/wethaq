<?php
header('Content-Type: application/json; charset=utf-8');

$mysqli = @new mysqli('127.0.0.1', 'root', '', 'wethaq_db');
if ($mysqli->connect_errno) { http_response_code(500); echo json_encode(['status'=>'error','message'=>'DB connect failed: '.$mysqli->connect_error]); exit; }
$mysqli->set_charset('utf8mb4');

$userId = intval($_POST['user_id'] ?? 0);
$name   = trim($_POST['name'] ?? '');
$email  = trim($_POST['email'] ?? '');
if ($email === '') $email = trim($_POST['new_email'] ?? '');
$phone  = trim($_POST['phone'] ?? '');
$idnum  = trim($_POST['identity_number'] ?? '');
$pass   = trim($_POST['password'] ?? '');

// قبول staff_user_id أو assigned_staff_user_id
$staffId = trim($_POST['staff_user_id'] ?? '');
if ($staffId === '') $staffId = trim($_POST['assigned_staff_user_id'] ?? '');

if ($userId <= 0) { http_response_code(400); echo json_encode(['status'=>'error','message'=>'user_id required']); exit; }

if ($pass !== '') {
    $stmt = $mysqli->prepare("UPDATE users SET name=?, email=?, phone=?, identity_number=?, password=? WHERE id=? AND role='Parent'");
    $stmt->bind_param('sssssi', $name, $email, $phone, $idnum, $pass, $userId);
} else {
    $stmt = $mysqli->prepare("UPDATE users SET name=?, email=?, phone=?, identity_number=? WHERE id=? AND role='Parent'");
    $stmt->bind_param('ssssi', $name, $email, $phone, $idnum, $userId);
}
if (!$stmt->execute()) { http_response_code(500); echo json_encode(['status'=>'error','message'=>'Update user failed: '.$stmt->error]); exit; }
$stmt->close();

if ($staffId !== '') {
    $stmt = $mysqli->prepare("UPDATE parents SET staff_user_id=? WHERE parent_user_id=?");
    $sid = (int)$staffId;
    $stmt->bind_param('ii', $sid, $userId);
    if (!$stmt->execute()) { http_response_code(500); echo json_encode(['status'=>'error','message'=>'Update parent link failed: '.$stmt->error]); exit; }
    $stmt->close();
}

echo json_encode(['status'=>'success','message'=>'Parent updated'], JSON_UNESCAPED_UNICODE);
?>
