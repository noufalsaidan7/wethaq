<?php
declare(strict_types=1);
header('Content-Type: application/json; charset=utf-8');
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
try {
  $conn = new mysqli('localhost','root','','wethaq_db');
  $conn->set_charset('utf8mb4');

  $sql = "SELECT u.id as id, u.name as name, u.email as email, u.phone as phone,
                 p.identity_number, p.assigned_staff_user_id
          FROM users u
          JOIN parents p ON p.parent_user_id = u.id
          ORDER BY u.name";
  $res = $conn->query($sql);
  $items = [];
  while ($r = $res->fetch_assoc()) $items[] = $r;

  echo json_encode(['status'=>'success','items'=>$items]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(['status'=>'error','message'=>$e->getMessage()]);
}
