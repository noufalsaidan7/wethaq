<?php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");

$mysqli = new mysqli("localhost","root","","wethaq_db");
if($mysqli->connect_errno){ echo json_encode(["status"=>"error","message"=>"DB"]); exit; }

$staff = $_GET['staff_user_id'] ?? '';
if(empty($staff)){ echo json_encode(["status"=>"error","message"=>"staff required"]); exit; }

$sql = "SELECT id,title,body,parent_user_id,created_at FROM announcements WHERE staff_user_id=? ORDER BY id DESC";
$stmt=$mysqli->prepare($sql); $stmt->bind_param("i",$staff); $stmt->execute();
$res=$stmt->get_result(); $items=[]; while($r=$res->fetch_assoc()) $items[]=$r;
echo json_encode(["status"=>"success","items"=>$items]);
