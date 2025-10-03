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

  // فلاتر اختيارية:
  // parent_user_id => للأب (يعرض العام + المخصص له)
  // staff_user_id  => للستاف (يعرض ما أرسله + العام) - للحفاظ على التوافق لو تستعملينه
  $parentId = isset($_GET['parent_user_id']) ? (int)$_GET['parent_user_id'] : 0;
  $staffId  = isset($_GET['staff_user_id'])  ? (int)$_GET['staff_user_id']  : 0;

  if ($parentId > 0) {
    $sql = "
      SELECT a.id, a.title, a.body, a.created_at,
             a.staff_user_id, a.parent_user_id,
             su.name  AS staff_name,
             su.email AS staff_email
      FROM announcements a
      LEFT JOIN users su ON su.id = a.staff_user_id
      WHERE (a.parent_user_id IS NULL OR a.parent_user_id = ?)
      ORDER BY a.created_at DESC, a.id DESC
      LIMIT 200
    ";
    $st = $conn->prepare($sql);
    $st->bind_param('i', $parentId);
    $st->execute();
    $res = $st->get_result();

  } elseif ($staffId > 0) {
    // لواجهة الستاف (قراءة): العام + ما أرسله
    $sql = "
      SELECT a.id, a.title, a.body, a.created_at,
             a.staff_user_id, a.parent_user_id,
             pu.name  AS parent_name,
             pu.email AS parent_email
      FROM announcements a
      LEFT JOIN users pu ON pu.id = a.parent_user_id
      WHERE (a.parent_user_id IS NULL OR a.staff_user_id = ?)
      ORDER BY a.created_at DESC, a.id DESC
      LIMIT 200
    ";
    $st = $conn->prepare($sql);
    $st->bind_param('i', $staffId);
    $st->execute();
    $res = $st->get_result();

  } else {
    // بدون فلاتر: العامة فقط (تستخدم للأدمن مثلاً)
    $sql = "
      SELECT a.id, a.title, a.body, a.created_at,
             a.staff_user_id, a.parent_user_id
      FROM announcements a
      WHERE a.parent_user_id IS NULL
      ORDER BY a.created_at DESC, a.id DESC
      LIMIT 200
    ";
    $res = $conn->query($sql);
  }

  $items = [];
  while ($row = $res->fetch_assoc()) {
    $items[] = [
      'id'              => (int)$row['id'],
      'title'           => $row['title'],
      'body'            => $row['body'],
      'created_at'      => $row['created_at'],
      'staff_user_id'   => isset($row['staff_user_id']) ? (int)$row['staff_user_id'] : null,
      'parent_user_id'  => isset($row['parent_user_id']) ? (int)$row['parent_user_id'] : null,
      'staff_name'      => $row['staff_name'] ?? null,
      'staff_email'     => $row['staff_email'] ?? null,
      'parent_name'     => $row['parent_name'] ?? null,
      'parent_email'    => $row['parent_email'] ?? null,
    ];
  }

  echo json_encode(['status'=>'success','items'=>$items], JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(['status'=>'error','message'=>$e->getMessage()]);
}
