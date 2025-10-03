<?php
header('Content-Type: application/json; charset=utf-8');

$mysqli = @new mysqli('127.0.0.1', 'root', '', 'wethaq_db');
if ($mysqli->connect_errno) { http_response_code(500); echo json_encode(['status'=>'error','message'=>'DB connect failed: '.$mysqli->connect_error]); exit; }
$mysqli->set_charset('utf8mb4');

$userId = intval($_POST['user_id'] ?? 0);
if ($userId <= 0) { http_response_code(400); echo json_encode(['status'=>'error','message'=>'user_id required']); exit; }

/* لو عندك FK ON DELETE CASCADE يكفي حذف users.
   ولو ما عندك FK: احذف من parents ثم users. */
$mysqli->begin_transaction();
try {
    $stmt = $mysqli->prepare("DELETE FROM parents WHERE parent_user_id=?");
    $stmt->bind_param('i', $userId);
    if (!$stmt->execute()) throw new Exception($stmt->error);
    $stmt->close();

    $stmt = $mysqli->prepare("DELETE FROM users WHERE id=? AND role='Parent'");
    $stmt->bind_param('i', $userId);
    if (!$stmt->execute()) throw new Exception($stmt->error);
    $stmt->close();

    $mysqli->commit();
    echo json_encode(['status'=>'success','message'=>'Parent deleted']);
} catch (Exception $e) {
    $mysqli->rollback();
    http_response_code(500);
    echo json_encode(['status'=>'error','message'=>'Delete failed: '.$e->getMessage()]);
}
?>
