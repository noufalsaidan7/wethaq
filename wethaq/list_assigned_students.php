<?php
declare(strict_types=1);
header('Content-Type: application/json; charset=utf-8');
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
while (ob_get_level() > 0) { ob_end_clean(); }

try {
  if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'GET') {
    http_response_code(405);
    echo json_encode(['status'=>'error','message'=>'Method Not Allowed']); exit;
  }

  $staffUserId = isset($_GET['staff_user_id']) ? (int)$_GET['staff_user_id'] : 0;
  if ($staffUserId <= 0) {
    http_response_code(400);
    echo json_encode(['status'=>'error','message'=>'Missing or invalid staff_user_id']); exit;
  }

  $conn = new mysqli('localhost','root','', 'wethaq_db');
  $conn->set_charset('utf8mb4');

  $sql = "
    SELECT
      c.id         AS child_id,
      c.child_name AS child_name,
      c.class      AS class,
      up.name      AS parent_name,
      up.email     AS parent_email
    FROM parents p
    INNER JOIN users up   ON up.id = p.parent_user_id AND up.role='Parent'
    INNER JOIN children c ON c.parent_user_id = p.parent_user_id
    WHERE p.staff_user_id = ?
    ORDER BY c.child_name ASC, c.id ASC
  ";

  $st=$conn->prepare($sql);
  $st->bind_param('i',$staffUserId);
  $st->execute();
  $res=$st->get_result();

  $items=[];
  while ($r = $res->fetch_assoc()) { $items[]=$r; }

  echo json_encode(['status'=>'success','items'=>$items], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(['status'=>'error','message'=>$e->getMessage()]);
}
