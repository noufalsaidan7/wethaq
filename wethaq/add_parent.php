<?php
header('Content-Type: application/json; charset=utf-8');

$mysqli = @new mysqli('127.0.0.1', 'root', '', 'wethaq_db');
if ($mysqli->connect_errno) { http_response_code(500); echo json_encode(['status'=>'error','message'=>'DB connect failed: '.$mysqli->connect_error]); exit; }
$mysqli->set_charset('utf8mb4');

$name    = trim($_POST['name'] ?? '');
$email   = trim($_POST['email'] ?? '');
$pass    = trim($_POST['password'] ?? '');
$phone   = trim($_POST['phone'] ?? '');
$idnum   = trim($_POST['identity_number'] ?? '');

// قبول staff_user_id أو assigned_staff_user_id
$staffId = trim($_POST['staff_user_id'] ?? '');
if ($staffId === '') $staffId = trim($_POST['assigned_staff_user_id'] ?? '');

if ($name==='' || $email==='' || $pass==='' || $staffId==='') {
    http_response_code(400);
    echo json_encode(['status'=>'error','message'=>'Missing (name,email,password,staff_user_id)']);
    exit;
}

$stmt = $mysqli->prepare("INSERT INTO users (name,email,password,phone,role,identity_number) VALUES (?,?,?,?, 'Parent', ?)");
$stmt->bind_param('sssss', $name, $email, $pass, $phone, $idnum);
if (!$stmt->execute()) { http_response_code(500); echo json_encode(['status'=>'error','message'=>'Insert user failed: '.$stmt->error]); exit; }
$parentUserId = $stmt->insert_id;
$stmt->close();

$stmt = $mysqli->prepare("INSERT INTO parents (parent_user_id, staff_user_id) VALUES (?,?)");
$staffIdInt = (int)$staffId;
$stmt->bind_param('ii', $parentUserId, $staffIdInt);
if (!$stmt->execute()) { http_response_code(500); echo json_encode(['status'=>'error','message'=>'Insert parent link failed: '.$stmt->error]); exit; }
$stmt->close();

echo json_encode(['status'=>'success','message'=>'Parent added','parent_user_id'=>$parentUserId], JSON_UNESCAPED_UNICODE);
?>
