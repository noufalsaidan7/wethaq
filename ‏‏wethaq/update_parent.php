<?php
declare(strict_types=1);
header('Content-Type: application/json; charset=utf-8');
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

try {
  if ($_SERVER['REQUEST_METHOD'] !== 'POST') { http_response_code(405); echo json_encode(['status'=>'error','message'=>'Method Not Allowed']); exit; }
  $conn = new mysqli('localhost','root','','wethaq_db');
  $conn->set_charset('utf8mb4');

  $parent_user_id = trim($_POST['user_id'] ?? '');
  if ($parent_user_id==='') { http_response_code(400); echo json_encode(['status'=>'error','message'=>'Missing parent id']); exit; }
  $name = trim($_POST['name'] ?? '');
  $new_email = trim($_POST['new_email'] ?? '');
  $phone = trim($_POST['phone'] ?? '');
  $identity_number = trim($_POST['identity_number'] ?? '');
  $assigned_staff_user_id = trim($_POST['assigned_staff_user_id'] ?? '');

  // check parent exists
  $q=$conn->prepare("SELECT id FROM users WHERE id=? AND role='Parent' LIMIT 1");
  $q->bind_param('i',$parent_user_id); $q->execute(); $res=$q->get_result();
  if ($res->num_rows===0) { http_response_code(400); echo json_encode(['status'=>'error','message'=>'Parent not found']); exit; }

  // validate assigned staff if provided
  if ($assigned_staff_user_id!=='') {
    $qs = $conn->prepare("SELECT id FROM users WHERE id=? AND role='Staff' LIMIT 1");
    $qs->bind_param('i',$assigned_staff_user_id); $qs->execute(); $rs=$qs->get_result();
    if ($rs->num_rows===0) { http_response_code(400); echo json_encode(['status'=>'error','message'=>'Invalid assigned_staff_user_id']); exit; }
  } else {
    http_response_code(400); echo json_encode(['status'=>'error','message'=>'assigned_staff_user_id required']); exit;
  }

  // update users table
  $fields=[]; $types=''; $vals=[];
  if ($name!==''){ $fields[]='name=?'; $types.='s'; $vals[]=$name; }
  if ($new_email!==''){ $fields[]='email=?'; $types.='s'; $vals[]=$new_email; }
  if ($phone!==''){ $fields[]='phone=?'; $types.='s'; $vals[]=$phone; }
  if ($fields) {
    $types .= 'i';
    $vals[] = $parent_user_id;
    $sql = 'UPDATE users SET '.implode(',',$fields).' WHERE id=?';
    $st = $conn->prepare($sql);
    $st->bind_param($types, ...$vals);
    $st->execute();
  }

  // update parents
  $pf=[]; $pt=''; $pv=[];
  if ($identity_number!=='') { $pf[]='identity_number=?'; $pt.='s'; $pv[]=$identity_number; }
  if ($assigned_staff_user_id!=='') { $pf[]='assigned_staff_user_id=?'; $pt.='i'; $pv[]=$assigned_staff_user_id; }
  if ($pf) {
    $pt .= 'i'; $pv[] = $parent_user_id;
    $sql='UPDATE parents SET '.implode(',',$pf).' WHERE parent_user_id=?';
    $sp = $conn->prepare($sql);
    $sp->bind_param($pt, ...$pv);
    $sp->execute();
  }

  echo json_encode(['status'=>'success','message'=>'Parent updated','parent_user_id'=>$parent_user_id]);
} catch (Throwable $e) {
  http_response_code(500); echo json_encode(['status'=>'error','message'=>$e->getMessage()]);
}
