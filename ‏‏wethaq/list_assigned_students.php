<?php
declare(strict_types=1);
header('Content-Type: application/json; charset=utf-8');
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
while (ob_get_level()>0) { ob_end_clean(); }

try {
  $conn = new mysqli('localhost','root','', 'wethaq_db');
  $conn->set_charset('utf8mb4');

  $staffId = (int)($_GET['staff_user_id'] ?? 0);
  if ($staffId <= 0) {
    http_response_code(400);
    echo json_encode(['status'=>'error','message'=>'Missing staff_user_id']); exit;
  }

  $sql = "
  SELECT 
    c.id         AS child_id,
    c.child_name AS child_name,
    c.class      AS class,
    u.name       AS parent_name,
    u.email      AS parent_email,
    u.id         AS parent_user_id
  FROM parents p
  JOIN users   u ON u.id = p.parent_user_id
  JOIN children c ON c.parent_user_id = p.parent_user_id
  WHERE p.staff_user_id = ?
  ORDER BY c.child_name ASC";
  $st=$conn->prepare($sql);
  $st->bind_param('i',$staffId);
  $st->execute();
  $res=$st->get_result();

  $items=[];
  while($row=$res->fetch_assoc()) $items[]=$row;

  echo json_encode(['status'=>'success','items'=>$items]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(['status'=>'error','message'=>$e->getMessage()]);
}