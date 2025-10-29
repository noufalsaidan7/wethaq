-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: 26 أكتوبر 2025 الساعة 21:04
-- إصدار الخادم: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `wethaq_db`
--

-- --------------------------------------------------------

--
-- بنية الجدول `announcements`
--

CREATE TABLE `announcements` (
  `id` int(10) UNSIGNED NOT NULL,
  `staff_user_id` int(10) UNSIGNED NOT NULL,
  `parent_user_id` int(10) UNSIGNED DEFAULT NULL,
  `title` varchar(200) NOT NULL,
  `body` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- إرجاع أو استيراد بيانات الجدول `announcements`
--

INSERT INTO `announcements` (`id`, `staff_user_id`, `parent_user_id`, `title`, `body`, `created_at`) VALUES
(1, 2, NULL, 'Welcome', 'This is a demo announcement.', '2025-10-26 16:02:04');

-- --------------------------------------------------------

--
-- بنية الجدول `attendance_states`
--

CREATE TABLE `attendance_states` (
  `child_id` int(10) UNSIGNED NOT NULL,
  `morning_parent_dropped` tinyint(1) NOT NULL DEFAULT 0,
  `morning_teacher_confirm` tinyint(1) NOT NULL DEFAULT 0,
  `noon_parent_waiting` tinyint(1) NOT NULL DEFAULT 0,
  `noon_teacher_released` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- بنية الجدول `children`
--

CREATE TABLE `children` (
  `id` int(10) UNSIGNED NOT NULL,
  `child_name` varchar(150) NOT NULL,
  `class` varchar(80) DEFAULT NULL,
  `parent_user_id` int(10) UNSIGNED NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- إرجاع أو استيراد بيانات الجدول `children`
--

INSERT INTO `children` (`id`, `child_name`, `class`, `parent_user_id`, `created_at`) VALUES
(1, 'Child A', 'KG-1', 3, '2025-10-26 16:02:04');

-- --------------------------------------------------------

--
-- بنية الجدول `child_schedule`
--

CREATE TABLE `child_schedule` (
  `child_id` int(10) UNSIGNED NOT NULL,
  `attendance_sun` varchar(20) DEFAULT '',
  `attendance_mon` varchar(20) DEFAULT '',
  `attendance_tue` varchar(20) DEFAULT '',
  `attendance_wed` varchar(20) DEFAULT '',
  `attendance_thu` varchar(20) DEFAULT '',
  `dismissal_sun` varchar(20) DEFAULT '',
  `dismissal_mon` varchar(20) DEFAULT '',
  `dismissal_tue` varchar(20) DEFAULT '',
  `dismissal_wed` varchar(20) DEFAULT '',
  `dismissal_thu` varchar(20) DEFAULT '',
  `published` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- إرجاع أو استيراد بيانات الجدول `child_schedule`
--

INSERT INTO `child_schedule` (`child_id`, `attendance_sun`, `attendance_mon`, `attendance_tue`, `attendance_wed`, `attendance_thu`, `dismissal_sun`, `dismissal_mon`, `dismissal_tue`, `dismissal_wed`, `dismissal_thu`, `published`) VALUES
(1, '07:00', '07:00', '', '', '', '', '', '', '', '', 1);

-- --------------------------------------------------------

--
-- بنية الجدول `device_tokens`
--

CREATE TABLE `device_tokens` (
  `id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `role` enum('Admin','Staff','Parent') NOT NULL,
  `token` varchar(255) NOT NULL,
  `platform` enum('android','ios','web') DEFAULT 'android',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- بنية الجدول `messages`
--

CREATE TABLE `messages` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `staff_user_id` int(10) UNSIGNED NOT NULL,
  `parent_user_id` int(10) UNSIGNED NOT NULL,
  `child_id` int(10) UNSIGNED DEFAULT NULL,
  `sender_role` enum('Staff','Parent') NOT NULL,
  `body` text NOT NULL,
  `reply_to_message_id` bigint(20) UNSIGNED DEFAULT NULL,
  `deleted_by_staff` tinyint(1) NOT NULL DEFAULT 0,
  `deleted_by_parent` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- إرجاع أو استيراد بيانات الجدول `messages`
--

INSERT INTO `messages` (`id`, `staff_user_id`, `parent_user_id`, `child_id`, `sender_role`, `body`, `reply_to_message_id`, `deleted_by_staff`, `deleted_by_parent`, `created_at`) VALUES
(1, 2, 3, 1, 'Staff', 'Hello, parent!', NULL, 0, 0, '2025-10-26 16:02:04'),
(2, 2, 3, 1, 'Parent', 'Hi teacher 👋', NULL, 0, 0, '2025-10-26 16:02:04');

-- --------------------------------------------------------

--
-- بنية الجدول `notifications`
--

CREATE TABLE `notifications` (
  `id` int(10) UNSIGNED NOT NULL,
  `sender_user_id` int(10) UNSIGNED NOT NULL,
  `receiver_user_id` int(10) UNSIGNED NOT NULL,
  `title` varchar(200) NOT NULL,
  `body` text NOT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- بنية الجدول `parents`
--

CREATE TABLE `parents` (
  `parent_user_id` int(10) UNSIGNED NOT NULL,
  `staff_user_id` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- إرجاع أو استيراد بيانات الجدول `parents`
--

INSERT INTO `parents` (`parent_user_id`, `staff_user_id`) VALUES
(3, 2);

-- --------------------------------------------------------

--
-- بنية الجدول `users`
--

CREATE TABLE `users` (
  `id` int(10) UNSIGNED NOT NULL,
  `name` varchar(150) NOT NULL,
  `email` varchar(190) NOT NULL,
  `role` enum('Admin','Staff','Parent') NOT NULL,
  `password` varchar(255) NOT NULL,
  `phone` varchar(40) DEFAULT NULL,
  `identity_number` varchar(40) DEFAULT NULL,
  `employee_number` varchar(20) DEFAULT NULL,
  `children` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`children`)),
  `must_change_password` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- إرجاع أو استيراد بيانات الجدول `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `role`, `password`, `phone`, `identity_number`, `employee_number`, `children`, `must_change_password`, `created_at`, `updated_at`) VALUES
(1, 'System Admin', 'admin@wethaq.com', 'Admin', 'admin123', NULL, NULL, NULL, NULL, 0, '2025-10-26 16:02:04', '2025-10-26 16:02:04'),
(2, 'Test Staff', 'staff1@wethaq.com', 'Staff', 'staff123', '0500000001', NULL, NULL, NULL, 0, '2025-10-26 16:02:04', '2025-10-26 16:02:04'),
(3, 'Test Parent', 'parent1@wethaq.com', 'Parent', 'parent123', '0500000002', NULL, NULL, NULL, 0, '2025-10-26 16:02:04', '2025-10-26 16:02:04');

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_parent_chat_list`
-- (See below for the actual view)
--
CREATE TABLE `vw_parent_chat_list` (
`parent_user_id` int(10) unsigned
,`staff_user_id` int(10) unsigned
,`staff_name` varchar(150)
,`staff_email` varchar(190)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_staff_chat_list`
-- (See below for the actual view)
--
CREATE TABLE `vw_staff_chat_list` (
`child_id` int(10) unsigned
,`child_name` varchar(150)
,`class` varchar(80)
,`parent_user_id` int(10) unsigned
,`parent_name` varchar(150)
,`parent_email` varchar(190)
,`staff_user_id` int(10) unsigned
);

-- --------------------------------------------------------

--
-- Structure for view `vw_parent_chat_list`
--
DROP TABLE IF EXISTS `vw_parent_chat_list`;

CREATE ALGORITHM=UNDEFINED DEFINER=`` SQL SECURITY DEFINER VIEW `vw_parent_chat_list`  AS SELECT `p`.`parent_user_id` AS `parent_user_id`, `p`.`staff_user_id` AS `staff_user_id`, `us`.`name` AS `staff_name`, `us`.`email` AS `staff_email` FROM (`parents` `p` join `users` `us` on(`us`.`id` = `p`.`staff_user_id` and `us`.`role` = 'Staff')) ;

-- --------------------------------------------------------

--
-- Structure for view `vw_staff_chat_list`
--
DROP TABLE IF EXISTS `vw_staff_chat_list`;

CREATE ALGORITHM=UNDEFINED DEFINER=`` SQL SECURITY DEFINER VIEW `vw_staff_chat_list`  AS SELECT `c`.`id` AS `child_id`, `c`.`child_name` AS `child_name`, `c`.`class` AS `class`, `p`.`parent_user_id` AS `parent_user_id`, `up`.`name` AS `parent_name`, `up`.`email` AS `parent_email`, `p`.`staff_user_id` AS `staff_user_id` FROM ((`parents` `p` join `users` `up` on(`up`.`id` = `p`.`parent_user_id` and `up`.`role` = 'Parent')) join `children` `c` on(`c`.`parent_user_id` = `p`.`parent_user_id`)) ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `announcements`
--
ALTER TABLE `announcements`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_ann_staff` (`staff_user_id`),
  ADD KEY `idx_ann_parent` (`parent_user_id`);

--
-- Indexes for table `attendance_states`
--
ALTER TABLE `attendance_states`
  ADD PRIMARY KEY (`child_id`);

--
-- Indexes for table `children`
--
ALTER TABLE `children`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_children_parent` (`parent_user_id`);

--
-- Indexes for table `child_schedule`
--
ALTER TABLE `child_schedule`
  ADD PRIMARY KEY (`child_id`),
  ADD KEY `idx_child_schedule_pub` (`published`);

--
-- Indexes for table `device_tokens`
--
ALTER TABLE `device_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_token` (`token`),
  ADD KEY `idx_user_role` (`user_id`,`role`);

--
-- Indexes for table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_msg_pair_time` (`staff_user_id`,`parent_user_id`,`created_at`),
  ADD KEY `idx_msg_parent_time` (`parent_user_id`,`created_at`),
  ADD KEY `idx_msg_child_time` (`child_id`,`created_at`),
  ADD KEY `idx_msg_reply_to` (`reply_to_message_id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_receiver_user` (`receiver_user_id`),
  ADD KEY `fk_notify_sender` (`sender_user_id`);

--
-- Indexes for table `parents`
--
ALTER TABLE `parents`
  ADD PRIMARY KEY (`parent_user_id`),
  ADD KEY `idx_parents_staff` (`staff_user_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_users_email` (`email`),
  ADD KEY `idx_users_role` (`role`),
  ADD KEY `idx_users_employee_number` (`employee_number`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `announcements`
--
ALTER TABLE `announcements`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `children`
--
ALTER TABLE `children`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `device_tokens`
--
ALTER TABLE `device_tokens`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- قيود الجداول المُلقاة.
--

--
-- قيود الجداول `announcements`
--
ALTER TABLE `announcements`
  ADD CONSTRAINT `fk_ann_parent_user` FOREIGN KEY (`parent_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ann_staff_user` FOREIGN KEY (`staff_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- قيود الجداول `attendance_states`
--
ALTER TABLE `attendance_states`
  ADD CONSTRAINT `fk_att_child` FOREIGN KEY (`child_id`) REFERENCES `children` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- قيود الجداول `children`
--
ALTER TABLE `children`
  ADD CONSTRAINT `fk_children_parent_user` FOREIGN KEY (`parent_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- قيود الجداول `child_schedule`
--
ALTER TABLE `child_schedule`
  ADD CONSTRAINT `fk_sched_child` FOREIGN KEY (`child_id`) REFERENCES `children` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- قيود الجداول `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `fk_msg_child` FOREIGN KEY (`child_id`) REFERENCES `children` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_msg_parent_user` FOREIGN KEY (`parent_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_msg_reply_to2` FOREIGN KEY (`reply_to_message_id`) REFERENCES `messages` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_msg_staff_user` FOREIGN KEY (`staff_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- قيود الجداول `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `fk_notify_receiver` FOREIGN KEY (`receiver_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_notify_sender` FOREIGN KEY (`sender_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- قيود الجداول `parents`
--
ALTER TABLE `parents`
  ADD CONSTRAINT `fk_parents_parent_user` FOREIGN KEY (`parent_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_parents_staff_user` FOREIGN KEY (`staff_user_id`) REFERENCES `users` (`id`) ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
