<?php
declare(strict_types=1);
header('Content-Type: application/json; charset=utf-8');
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

try {
  if ($_SERVER['REQUEST_METHOD'] !== 'POST') { http_response_code(405); echo json_encode(['status'=>'error','message'=>'Method Not Allowed']); exit; }
  $conn = new mysqli('localhost','root','','wethaq_db');
  $conn->set_charset('utf8mb4');

  $user_id = trim($_POST['user_id'] ?? '');
  if ($user_id === '') { http_response_code(400); echo json_encode(['status'=>'error','message'=>'Missing user_id']); exit; }

  // تأكيد أنه Staff
  $chk = $conn->prepare("SELECT id FROM users WHERE id=? AND role='Staff' LIMIT 1");
  $chk->bind_param('i', $user_id);
  $chk->execute();
  $rs = $chk->get_result();
  if ($rs->num_rows === 0) { http_response_code(400); echo json_encode(['status'=>'error','message'=>'Staff not found']); exit; }

  // هل لديه آباء مرتبطين؟
  $q = $conn->prepare("SELECT COUNT(*) AS cnt FROM parents WHERE assigned_staff_user_id=?");
  $q->bind_param('i', $user_id);
  $q->execute();
  $c = $q->get_result()->fetch_assoc();
  if ((int)$c['cnt'] > 0) {
    http_response_code(400);
    echo json_encode(['status'=>'error','message'=>'Cannot delete staff: there are parents assigned. Reassign parents first.']);
    exit;
  }

  // احذف المستخدم
  $del = $conn->prepare("DELETE FROM users WHERE id=? AND role='Staff'");
  $del->bind_param('i', $user_id);
  $del->execute();

  echo json_encode(['status'=>'success','message'=>'Staff deleted']);
} catch (Throwable $e) {
  http_response_code(500); echo json_encode(['status'=>'error','message'=>$e->getMessage()]);
}
