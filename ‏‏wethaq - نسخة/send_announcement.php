<?php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");

$mysqli = new mysqli("localhost","root","","wethaq_db");
if($mysqli->connect_errno){ echo json_encode(["status"=>"error","message"=>"DB"]); exit; }

$staff = $_POST['staff_user_id'] ?? '';
$parent = $_POST['parent_user_id'] ?? ''; // اختياري (فارغ = للجميع)
$title = $_POST['title'] ?? '';
$body  = $_POST['body'] ?? '';

if(empty($staff) || empty($title) || empty($body)){
  echo json_encode(["status"=>"error","message"=>"Missing"]); exit;
}

if($parent==='') $stmt = $mysqli->prepare("INSERT INTO announcements(staff_user_id,parent_user_id,title,body) VALUES(?,NULL,?,?)");
else            $stmt = $mysqli->prepare("INSERT INTO announcements(staff_user_id,parent_user_id,title,body) VALUES(?,?,?,?)");

if($parent==='') $stmt->bind_param("iss",$staff,$title,$body);
else             $stmt->bind_param("iiss",$staff,$parent,$title,$body);

$ok = $stmt->execute();
echo json_encode($ok? ["status"=>"success"] : ["status"=>"error","message"=>"insert failed"]);
