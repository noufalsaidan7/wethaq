<?php
declare(strict_types=1);
header('Content-Type: application/json; charset=utf-8');

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

try {
  if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['status'=>'error','message'=>'Method Not Allowed']); exit;
  }

  $conn = new mysqli('localhost','root','', 'wethaq_db');
  $conn->set_charset('utf8mb4');

  // اختياري: فلترة حسب أب معيّن
  $parentId = isset($_GET['parent_user_id']) ? (int)$_GET['parent_user_id'] : 0;

  if ($parentId > 0) {
    // أبناء هذا الأب فقط
    $sql = "
      SELECT c.id,
             c.child_name,
             c.class,
             c.parent_user_id,
             u.name  AS parent_name,
             u.email AS parent_email
      FROM children c
      JOIN users u
        ON u.id = c.parent_user_id
      WHERE c.parent_user_id = ?
      ORDER BY c.id DESC
    ";
    $st = $conn->prepare($sql);
    $st->bind_param('i', $parentId);
    $st->execute();
    $res = $st->get_result();
  } else {
    // الكل (تستخدمينها بالأدمن مثل قبل)
    $sql = "
      SELECT c.id,
             c.child_name,
             c.class,
             c.parent_user_id,
             u.name  AS parent_name,
             u.email AS parent_email
      FROM children c
      JOIN users u
        ON u.id = c.parent_user_id
      ORDER BY c.id DESC
    ";
    $res = $conn->query($sql);
  }

  $items = [];
  while ($row = $res->fetch_assoc()) {
    $items[] = [
      'id'              => (int)$row['id'],
      'child_name'      => $row['child_name'],
      'class'           => $row['class'],
      'parent_user_id'  => (int)$row['parent_user_id'],
      'parent_name'     => $row['parent_name'],
      'parent_email'    => $row['parent_email'],
    ];
  }

  echo json_encode(['status'=>'success','items'=>$items], JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(['status'=>'error','message'=>$e->getMessage()]);
}
