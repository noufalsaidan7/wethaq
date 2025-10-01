<?php
declare(strict_types=1);
header('Content-Type: application/json; charset=utf-8');
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

// امنعي أي مخلفات HTML/BR
while (ob_get_level() > 0) { ob_end_clean(); }

try {
    // لازم GET فقط
    if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
        http_response_code(405);
        echo json_encode(['status'=>'error','message'=>'Method Not Allowed']);
        exit;
    }

    $conn = new mysqli('localhost','root','', 'wethaq_db');
    $conn->set_charset('utf8mb4');

    // نجيب الطفل + اسم الأب
    $sql = "SELECT c.id,
                   c.child_name,
                   c.class,
                   c.parent_user_id,
                   u.name  AS parent_name,
                   u.email AS parent_email
            FROM children c
            JOIN users u ON u.id = c.parent_user_id
            ORDER BY c.id DESC";
    $res = $conn->query($sql);

    $rows = [];
    while ($row = $res->fetch_assoc()) {
        $rows[] = $row;
    }

    // نرجّع نفس المصفوفة بمفتاحين (توافق للخلف)
    echo json_encode([
        'status'   => 'success',
        'children' => $rows,
        'items'    => $rows
    ]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['status'=>'error','message'=>$e->getMessage()]);
}
