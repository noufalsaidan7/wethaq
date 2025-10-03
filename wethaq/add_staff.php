<?php
declare(strict_types=1);
header('Content-Type: application/json; charset=utf-8');

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
while (ob_get_level()>0) { ob_end_clean(); }

try {
  if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status'=>'error','message'=>'Method Not Allowed']); exit;
  }

  $conn = new mysqli('localhost','root','', 'wethaq_db');
  $conn->set_charset('utf8mb4');

  $name  = trim($_POST['name'] ?? '');
  $email = trim($_POST['email'] ?? '');
  $pass  = trim($_POST['password'] ?? '');
  $phone = trim($_POST['phone'] ?? '');
  $empno = trim($_POST['employee_number'] ?? '');

  if ($name==='' || $email==='' || $pass==='') {
    http_response_code(400);
    echo json_encode(['status'=>'error','message'=>'Missing required fields']); exit;
  }

  // users
  $role = 'Staff';
  $u = $conn->prepare("INSERT INTO users (name,email,role,password,phone,employee_number) VALUES (?,?,?,?,?,?)");
  $u->bind_param('ssssss',$name,$email,$role,$pass,$phone,$empno);
  $u->execute();

  echo json_encode(['status'=>'success','message'=>'Staff added']);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(['status'=>'error','message'=>$e->getMessage()]);
}
