<?php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");

$mysqli = new mysqli("localhost","root","","wethaq_db");
if($mysqli->connect_errno){ echo json_encode(["status"=>"error","message"=>"DB"]); exit; }

$user_id = $_POST['user_id'] ?? '';
$new     = $_POST['new_password'] ?? '';

if(empty($user_id) || empty($new)){
  echo json_encode(["status"=>"error","message"=>"Missing fields"]); exit;
}

$stmt = $mysqli->prepare("UPDATE users SET password=?, must_change_password=0 WHERE id=?");
$stmt->bind_param("si",$new,$user_id);
$ok = $stmt->execute();

echo json_encode($ok? ["status"=>"success"] : ["status"=>"error","message"=>"update failed"]);
