<?php
declare(strict_types=1);
header('Content-Type: application/json; charset=utf-8');
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
try {
  $conn = new mysqli('localhost','root','','wethaq_db');
  $conn->set_charset('utf8mb4');

  $res = $conn->query("SELECT id, name, email, phone, employee_number FROM users WHERE role='Staff' ORDER BY name");
  $items = [];
  while ($r = $res->fetch_assoc()) $items[] = $r;

  echo json_encode(['status'=>'success','items'=>$items]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(['status'=>'error','message'=>$e->getMessage()]);
}