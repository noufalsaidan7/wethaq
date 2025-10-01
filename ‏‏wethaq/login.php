<?php
header('Content-Type: application/json; charset=utf-8');
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

try {
  if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status'=>'error','message'=>'Method Not Allowed']); exit;
  }

  $conn = new mysqli('localhost','root','', 'wethaq_db');
  $conn->set_charset('utf8mb4');

  $username = trim($_POST['username'] ?? '');
  $pass     = trim($_POST['password'] ?? '');

  if ($username === '' || $pass === '') {
    http_response_code(400);
    echo json_encode(['status'=>'error','message'=>'Missing username or password']); exit;
  }

  $q = $conn->prepare("SELECT id,name,email,role,password FROM users WHERE name=? LIMIT 1");
  $q->bind_param("s", $username);
  $q->execute();
  $res = $q->get_result();

  if ($res->num_rows === 0) {
    echo json_encode(['status'=>'error','message'=>'User not found']); exit;
  }

  $u = $res->fetch_assoc();

  if ($u['password'] !== $pass) {
    echo json_encode(['status'=>'error','message'=>'Invalid password']); exit;
  }

  echo json_encode([
    'status'=>'success',
    'message'=>'Login successful',
    'user'=>[
      'id'=>$u['id'],
      'name'=>$u['name'],
      'email'=>$u['email'],
      'role'=>$u['role']
    ]
  ]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(['status'=>'error','message'=>$e->getMessage()]);
}
