<?php
declare(strict_types=1);
header('Content-Type: application/json; charset=utf-8');


// فعّل أخطاء mysqli كاستثناءات
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

// نظّف أي خرج سابق
while (ob_get_level() > 0) { ob_end_clean(); }

try {
  // 1) السماح بـ POST فقط
  if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method Not Allowed']);
    exit;
  }

  // 2) اتّصال القاعدة
  $conn = new mysqli('localhost','root','', 'wethaq_db');
  $conn->set_charset('utf8mb4');

  // 3) قراءة المُدخلات
  $username = trim($_POST['username'] ?? '');
  $password = trim($_POST['password'] ?? '');

  if ($username === '' || $password === '') {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Missing username or password']);
    exit;
  }

  // 4) نجلب المستخدم حسب البريد (أو الاسم إذا حابة تسمحي)
  // افتراضياً تعتمدوا على البريد. لو تبي السماح بالاسم أيضاً نفحص كليهما.
  $q = $conn->prepare("
    SELECT id, name, email, role, password,
           COALESCE(must_change_password, 0) AS must_change_password
    FROM users
    WHERE email = ? OR name = ?
    LIMIT 1
  ");
  $q->bind_param('ss', $username, $username);
  $q->execute();
  $res = $q->get_result();

  if ($res->num_rows === 0) {
    http_response_code(401);
    echo json_encode(['status' => 'error', 'message' => 'Invalid credentials']);
    exit;
  }

  $row = $res->fetch_assoc();

  // 5) التحقق من كلمة المرور
  $dbPass = (string)$row['password'];
  $ok = false;

  // إذا مخزنة مشفرة (bcrypt, argon2 ...) نستخدم password_verify
  if (preg_match('/^\$2[aby]\$/', $dbPass) || str_starts_with($dbPass, '$argon')) {
    $ok = password_verify($password, $dbPass);
  } else {
    // نصيّة عادية
    $ok = hash_equals($dbPass, $password);
  }

  if (!$ok) {
    http_response_code(401);
    echo json_encode(['status' => 'error', 'message' => 'Invalid credentials']);
    exit;
  }

  // 6) نبني جسم المستخدم للواجهة
  $user = [
    'id'    => (int)$row['id'],
    'name'  => (string)$row['name'],
    'email' => (string)$row['email'],
    'role'  => (string)$row['role'],
    'must_change_password' => (int)$row['must_change_password'], // للستاف/الكل إن احتجتوه
  ];

  // 7) رجوع نجاح
  echo json_encode(['status' => 'success', 'user' => $user], JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
