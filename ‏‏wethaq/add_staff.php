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
  $employee_number = trim($_POST['employee_number'] ?? '');

  if ($name==='' || $email==='' || $password==='' || $employee_number==='') {
    http_response_code(400);
    echo json_encode(['status'=>'error','message'=>'Missing required fields']); exit;
  }

  // unique email
  $q=$conn->prepare("SELECT id FROM users WHERE email=? LIMIT 1");
  $q->bind_param('s',$email); $q->execute(); $r=$q->get_result();
  if ($r->num_rows>0) { http_response_code(400); echo json_encode(['status'=>'error','message'=>'Email already exists']); exit; }

  $stmt = $conn->prepare("INSERT INTO users (name,email,role,password,phone,employee_number) VALUES (?,?,?,?,?,?)");
  $role='Staff';
  $stmt->bind_param('ssssss',$name,$email,$role,$password,$phone,$employee_number);
  $stmt->execute();

  echo json_encode(['status'=>'success','message'=>'Staff added','id'=>$stmt->insert_id]);
} catch (Throwable $e) {
  http_response_code(500); echo json_encode(['status'=>'error','message'=>$e->getMessage()]);
}
