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

  $childId = (int)($_POST['child_id'] ?? 0);
  if ($childId <= 0) {
    http_response_code(400);
    echo json_encode(['status'=>'error','message'=>'Missing child_id']); exit;
  }

  $del = $conn->prepare("DELETE FROM children WHERE id=?");
  $del->bind_param('i', $childId);
  $del->execute();

  echo json_encode(['status'=>'success','message'=>'Child deleted']);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(['status'=>'error','message'=>$e->getMessage()]);
}
