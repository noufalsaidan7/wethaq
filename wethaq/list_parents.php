<?php
header('Content-Type: application/json; charset=utf-8');

$mysqli = @new mysqli('127.0.0.1', 'root', '', 'wethaq_db');
if ($mysqli->connect_errno) { http_response_code(500); echo json_encode(['status'=>'error','message'=>'DB connect failed: '.$mysqli->connect_error]); exit; }
$mysqli->set_charset('utf8mb4');

$sql = "
  SELECT
    u.id,
    u.name,
    u.email,
    u.phone,
    u.identity_number,
    p.staff_user_id,
    s.name AS staff_name
  FROM parents p
  JOIN users u ON u.id = p.parent_user_id
  JOIN users s ON s.id = p.staff_user_id
  ORDER BY u.name ASC
";
$res = $mysqli->query($sql);
if (!$res) { http_response_code(500); echo json_encode(['status'=>'error','message'=>'SQL error: '.$mysqli->error]); exit; }

$items = [];
while ($row = $res->fetch_assoc()) $items[] = $row;

echo json_encode(['status'=>'success','items'=>$items], JSON_UNESCAPED_UNICODE);
?>
