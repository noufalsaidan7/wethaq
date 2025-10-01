<?php
declare(strict_types=1);
header('Content-Type: application/json; charset=utf-8');
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

try {
  if ($_SERVER['REQUEST_METHOD'] !== 'POST') { http_response_code(405); echo json_encode(['status'=>'error','message'=>'Method Not Allowed']); exit; }
  $conn = new mysqli('localhost','root','','wethaq_db');
  $conn->set_charset('utf8mb4');

  $user_id = trim($_POST['user_id'] ?? '');
  if ($user_id==='') { http_response_code(400); echo json_encode(['status'=>'error','message'=>'Missing user_id']); exit; }

  // delete user row -> CASCADE will remove parent and children if set up
  $st = $conn->prepare("DELETE FROM users WHERE id=? AND role='Parent'");
  $st->bind_param('i',$user_id); $st->execute();

  if ($st->affected_rows>0) echo json_encode(['status'=>'success','message'=>'Parent deleted']);
  else { http_response_code(400); echo json_encode(['status'=>'error','message'=>'Parent not found']); }
} catch (Throwable $e) {
  http_response_code(500); echo json_encode(['status'=>'error','message'=>$e->getMessage()]);
}
