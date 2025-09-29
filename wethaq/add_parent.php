<?php
header('Content-Type: application/json; charset=utf-8');
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

try {
  $conn = new mysqli('localhost','root','','wethaq_db');
  $conn->set_charset('utf8mb4');

  if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status'=>'error','message'=>'Method Not Allowed']); exit;
  }

  $name = trim($_POST['name'] ?? '');
  $email = trim($_POST['email'] ?? '');
  $password = trim($_POST['password'] ?? '');
  $phone = trim($_POST['phone'] ?? '');
  $identity_number = trim($_POST['identity_number'] ?? '');
  $assigned_staff_email = trim($_POST['assigned_staff_email'] ?? '');
  $children_json = $_POST['children'] ?? '[]';

  if ($name==='' || $email==='' || $password==='') {
    http_response_code(400);
    echo json_encode(['status'=>'error','message'=>'Missing required fields']); exit;
  }

  $children_arr = json_decode($children_json, true);
  if (!is_array($children_arr)) $children_arr = [];

  $check = $conn->prepare("SELECT id FROM users WHERE email=? LIMIT 1");
  $check->bind_param("s",$email);
  $check->execute(); $check->store_result();
  if ($check->num_rows > 0) { echo json_encode(['status'=>'error','message'=>'Email already exists']); exit; }
  $check->close();

  if ($identity_number !== '') {
    $cp = $conn->prepare("SELECT user_id FROM parents WHERE identity_number=? LIMIT 1");
    $cp->bind_param("s",$identity_number);
    $cp->execute(); $cp->store_result();
    if ($cp->num_rows > 0) { echo json_encode(['status'=>'error','message'=>'Identity number already exists']); exit; }
    $cp->close();
  }

  $assigned_staff_user_id = null;
  if ($assigned_staff_email !== '') {
    $q = $conn->prepare("SELECT id FROM users WHERE email=? AND role='Member' LIMIT 1");
    $q->bind_param("s",$assigned_staff_email);
    $q->execute(); $q->bind_result($sid);
    if ($q->fetch()) $assigned_staff_user_id = $sid;
    $q->close();
  }

  $conn->begin_transaction();

  $role = 'Parent';
  $u = $conn->prepare("INSERT INTO users (name,email,role,password,phone) VALUES (?,?,?,?,?)");
  $u->bind_param("sssss",$name,$email,$role,$password,$phone);
  $u->execute();
  $parent_user_id = $u->insert_id;
  $u->close();

  if ($assigned_staff_user_id === null) {
    $p = $conn->prepare("INSERT INTO parents (user_id, identity_number, assigned_staff_user_id) VALUES (?,?,NULL)");
    $p->bind_param("is", $parent_user_id, $identity_number);
  } else {
    $p = $conn->prepare("INSERT INTO parents (user_id, identity_number, assigned_staff_user_id) VALUES (?,?,?)");
    $p->bind_param("isi", $parent_user_id, $identity_number, $assigned_staff_user_id);
  }
  $p->execute(); $p->close();

  if (!empty($children_arr)) {
    $c = $conn->prepare("INSERT INTO children (parent_user_id, child_name, class) VALUES (?,?,?)");
    foreach ($children_arr as $ch) {
      $child_name = trim($ch['name'] ?? '');
      $class = trim($ch['class'] ?? '');
      if ($child_name==='') continue;
      $c->bind_param("iss",$parent_user_id,$child_name,$class);
      $c->execute();
    }
    $c->close();
  }

  $conn->commit();
  echo json_encode(['status'=>'success','message'=>'Inserted','user_id'=>$parent_user_id]);

} catch (Throwable $e) {
  if (isset($conn)) { @$conn->rollback(); }
  http_response_code(500);
  echo json_encode(['status'=>'error','message'=>$e->getMessage()]);
}
