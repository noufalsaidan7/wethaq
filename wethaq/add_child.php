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

  $name   = trim($_POST['name'] ?? '');
  $class  = trim($_POST['class'] ?? '');
  $parent = trim($_POST['parent_id'] ?? '');

  if ($name==='' || $parent==='') {
    http_response_code(400);
    echo json_encode(['status'=>'error','message'=>'Missing required fields']); exit;
  }

  // تأكد أن الأب موجود وفعلاً role=Parent
  $q = $conn->prepare("SELECT id FROM users WHERE id=? AND role='Parent' LIMIT 1");
  $q->bind_param('i', $parent);
  $q->execute();
  $r = $q->get_result();
  if ($r->num_rows===0) {
    http_response_code(400);
    echo json_encode(['status'=>'error','message'=>'Invalid parent_id']); exit;
  }

  $ins = $conn->prepare(
    "INSERT INTO children (child_name, class, parent_user_id, created_at) VALUES (?,?,?,NOW())"
  );
  $ins->bind_param('ssi', $name, $class, $parent);
  $ins->execute();

  echo json_encode(['status'=>'success','message'=>'Child added','child_id'=>$ins->insert_id]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(['status'=>'error','message'=>$e->getMessage()]);
}
