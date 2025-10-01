<?php
declare(strict_types=1);
header('Content-Type: application/json; charset=utf-8');
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

try {
  if ($_SERVER['REQUEST_METHOD'] !== 'POST') { http_response_code(405); echo json_encode(['status'=>'error','message'=>'Method Not Allowed']); exit; }
  $conn = new mysqli('localhost','root','','wethaq_db');
  $conn->set_charset('utf8mb4');

  $name = trim($_POST['name'] ?? '');
  $email = trim($_POST['email'] ?? '');
  $password = trim($_POST['password'] ?? '');
  $phone = trim($_POST['phone'] ?? '');
  $identity_number = trim($_POST['identity_number'] ?? '');
  $assigned_staff_user_id = trim($_POST['assigned_staff_user_id'] ?? '');

  if ($name===''||$email===''||$password===''||$assigned_staff_user_id==='') {
    http_response_code(400);
    echo json_encode(['status'=>'error','message'=>'Missing required fields']);
    exit;
  }

  // check staff exists
  $qs = $conn->prepare("SELECT id FROM users WHERE id=? AND role='Staff' LIMIT 1");
  $qs->bind_param('i',$assigned_staff_user_id);
  $qs->execute(); $rs=$qs->get_result();
  if ($rs->num_rows===0) {
    http_response_code(400);
    echo json_encode(['status'=>'error','message'=>'Invalid assigned_staff_user_id']); exit;
  }

  // insert user
  $st = $conn->prepare("INSERT INTO users (name,email,role,password,phone) VALUES (?,?,?,?,?)");
  $role='Parent';
  $st->bind_param('sssss',$name,$email,$role,$password,$phone);
  $st->execute();
  $parentUserId = $st->insert_id;

  // insert parent record
  $p = $conn->prepare("INSERT INTO parents (parent_user_id, identity_number, assigned_staff_user_id) VALUES (?,?,?)");
  $p->bind_param('isi',$parentUserId,$identity_number,$assigned_staff_user_id);
  $p->execute();

  echo json_encode(['status'=>'success','message'=>'Parent added','parent_user_id'=>$parentUserId]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(['status'=>'error','message'=>$e->getMessage()]);
}
