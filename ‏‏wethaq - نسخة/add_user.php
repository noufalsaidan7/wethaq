<?php
header('Content-Type: application/json; charset=utf-8');
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

try {
  
  $servername = "localhost";
  $username   = "root";
  $password   = "";
  $dbname     = "wethaq_db"; 

  if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status'=>'error','message'=>'Method Not Allowed']); exit;
  }

  $conn = new mysqli($servername, $username, $password, $dbname);
  $conn->set_charset('utf8mb4');

  // استلام القيم
  $name  = isset($_POST['name']) ? trim($_POST['name']) : '';
  $email = isset($_POST['email']) ? trim($_POST['email']) : '';
  $role  = isset($_POST['role']) ? trim($_POST['role']) : '';
  $pwd   = isset($_POST['password']) ? trim($_POST['password']) : '';
  $phone = isset($_POST['phone']) ? trim($_POST['phone']) : '';
  $identity_number = isset($_POST['identity_number']) && $_POST['identity_number'] !== '' ? trim($_POST['identity_number']) : null;

  // children كـ JSON string
  $children = isset($_POST['children']) ? $_POST['children'] : '';
  if ($children === '' || $children === null) {
    $children = '[]';
  } else {
    // صحح JSON لو كان خربان
    $decoded = json_decode($children, true);
    if (!is_array($decoded)) {
      $children = '[]';
    } else {
      // أعِد ترميزه منظّف
      $children = json_encode($decoded, JSON_UNESCAPED_UNICODE);
    }
  }

  if ($name === '' || $email === '' || $role === '' || $pwd === '') {
    http_response_code(400);
    echo json_encode(['status'=>'error','message'=>'Missing required fields']); exit;
  }

  // ملاحظة: حالياً نخزن الباسورد كنص خام (لتوافق login الحالي)
  // يفضَّل مستقبلاً: password_hash / password_verify

  // تأكد أعمدة الجدول:
  // users(name,email,role,password,phone,identity_number,children)
  $stmt = $conn->prepare("
    INSERT INTO users (name, email, role, password, phone, identity_number, children)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  ");
  $stmt->bind_param("sssssss", $name, $email, $role, $pwd, $phone, $identity_number, $children);
  $stmt->execute();

  echo json_encode(['status'=>'success','message'=>'Inserted','user_id'=>$conn->insert_id]);
  $stmt->close();
  $conn->close();

} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(['status'=>'error','message'=>$e->getMessage()]);
}
