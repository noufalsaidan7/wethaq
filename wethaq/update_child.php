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
  $name    = trim($_POST['name'] ?? '');
  $class   = trim($_POST['class'] ?? '');
  $parent  = trim($_POST['parent_id'] ?? '');

  if ($childId <= 0) {
    http_response_code(400);
    echo json_encode(['status'=>'error','message'=>'Missing child_id']); exit;
  }

  // تأكد الطفل موجود
  $ck = $conn->prepare("SELECT id FROM children WHERE id=? LIMIT 1");
  $ck->bind_param('i', $childId);
  $ck->execute();
  if ($ck->get_result()->num_rows === 0) {
    http_response_code(404);
    echo json_encode(['status'=>'error','message'=>'Child not found']); exit;
  }

  // نبني جملة التحديث ديناميكياً
  $fields=[]; $types=''; $vals=[];
  if ($name!==''){ $fields[]='child_name=?'; $types.='s'; $vals[]=$name; }
  if ($class!==''){ $fields[]='class=?';      $types.='s'; $vals[]=$class; }
  if ($parent!==''){
    // تحقق من الأب
    $pid = (int)$parent;
    $q = $conn->prepare("SELECT id FROM users WHERE id=? AND role='Parent' LIMIT 1");
    $q->bind_param('i', $pid); $q->execute();
    if ($q->get_result()->num_rows===0) {
      http_response_code(400);
      echo json_encode(['status'=>'error','message'=>'Invalid parent_id']); exit;
    }
    $fields[]='parent_user_id=?'; $types.='i'; $vals[]=$pid;
  }

  if (!$fields) { echo json_encode(['status'=>'success','message'=>'No changes']); exit; }

  $sql = 'UPDATE children SET '.implode(',', $fields).' WHERE id=?';
  $types.='i'; $vals[]=$childId;

  $st = $conn->prepare($sql);
  $st->bind_param($types, ...$vals);
  $st->execute();

  echo json_encode(['status'=>'success','message'=>'Child updated']);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(['status'=>'error','message'=>$e->getMessage()]);
}
