<?php
declare(strict_types=1);
header('Content-Type: application/json; charset=utf-8');
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
while (ob_get_level()>0) { ob_end_clean(); }

try {
  $staffUserId = isset($_GET['staff_user_id']) ? (int)$_GET['staff_user_id'] : 0;
  if ($staffUserId<=0) { http_response_code(400); echo json_encode(['status'=>'error','message'=>'Missing staff_user_id']); exit; }

  $conn = new mysqli('localhost','root','', 'wethaq_db');
  $conn->set_charset('utf8mb4');

  $sql="SELECT p.parent_user_id, u.name, u.email
        FROM parents p INNER JOIN users u ON u.id=p.parent_user_id
        WHERE p.staff_user_id=? ORDER BY u.name";
  $st=$conn->prepare($sql); $st->bind_param('i',$staffUserId); $st->execute();
  $res=$st->get_result();
  $items=[]; while($r=$res->fetch_assoc()) $items[]=$r;

  echo json_encode(['status'=>'success','items'=>$items], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(['status'=>'error','message'=>$e->getMessage()]);
}
