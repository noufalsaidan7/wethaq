<?php
header('Content-Type: application/json; charset=utf-8');
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

try {
  $conn = new mysqli('localhost','root','','wethaq_db');
  $conn->set_charset('utf8mb4');

  if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status'=>'error','message'=>'Method Not Allowed']); exit;
  }

  $name = trim($_POST['name'] ?? '');
  $email = trim($_POST['email'] ?? '');
  $password = trim($_POST['password'] ?? '');
  $phone = trim($_POST['phone'] ?? '');
  $employee_number = trim($_POST['employee_number'] ?? '');

  if ($name==='' || $email==='' || $password==='' || $employee_number==='') {
    http_response_code(400);
    echo json_encode(['status'=>'error','message'=>'Missing required fields']); exit;
  }

  $check = $conn->prepare("SELECT id FROM users WHERE email=? LIMIT 1");
  $check->bind_param("s",$email);
  $check->execute(); $check->store_result();
  if ($check->num_rows > 0) { echo json_encode(['status'=>'error','message'=>'Email already exists']); exit; }
  $check->close();

  $check2 = $conn->prepare("SELECT user_id FROM staff WHERE employee_number=? LIMIT 1");
  $check2->bind_param("s",$employee_number);
  $check2->execute(); $check2->store_result();
  if ($check2->num_rows > 0) { echo json_encode(['status'=>'error','message'=>'Employee number already exists']); exit; }
  $check2->close();

  $conn->begin_transaction();

  $role = 'Member';
  $u = $conn->prepare("INSERT INTO users (name,email,role,password,phone) VALUES (?,?,?,?,?)");
  $u->bind_param("sssss",$name,$email,$role,$password,$phone);
  $u->execute();
  $user_id = $u->insert_id;
  $u->close();

  $s = $conn->prepare("INSERT INTO staff (user_id,employee_number) VALUES (?,?)");
  $s->bind_param("is",$user_id,$employee_number);
  $s->execute(); $s->close();

  $conn->commit();
  echo json_encode(['status'=>'success','message'=>'Inserted','user_id'=>$user_id]);

} catch (Throwable $e) {
  if (isset($conn)) { @$conn->rollback(); }
  http_response_code(500);
  echo json_encode(['status'=>'error','message'=>$e->getMessage()]);
}
