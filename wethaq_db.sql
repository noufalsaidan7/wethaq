-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: 01 أكتوبر 2025 الساعة 20:21
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- بنية الجدول `children`
--

CREATE TABLE `children` (
  `id` int(10) UNSIGNED NOT NULL,
  `parent_user_id` int(10) UNSIGNED NOT NULL,
  `child_name` varchar(120) NOT NULL,
  `class` varchar(80) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- إرجاع أو استيراد بيانات الجدول `children`
--

INSERT INTO `children` (`id`, `parent_user_id`, `child_name`, `class`, `created_at`) VALUES
(1, 3, 'Child A', '1A', '2025-10-01 16:51:01'),
(3, 3, 'loly', 'A3', '2025-10-01 17:18:40'),
(4, 3, 'lok', 'f', '2025-10-01 17:28:10');

--
-- القوادح `children`
--
DELIMITER $$
CREATE TRIGGER `bi_children_parent_role` BEFORE INSERT ON `children` FOR EACH ROW BEGIN
  IF (SELECT role FROM users WHERE id = NEW.parent_user_id) <> 'Parent' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'children.parent_user_id must reference a Parent user';
  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `bu_children_parent_role` BEFORE UPDATE ON `children` FOR EACH ROW BEGIN
  IF (SELECT role FROM users WHERE id = NEW.parent_user_id) <> 'Parent' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'children.parent_user_id must reference a Parent user';
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- بنية الجدول `parents`
--

CREATE TABLE `parents` (
  `parent_user_id` int(10) UNSIGNED NOT NULL,
  `assigned_staff_user_id` int(10) UNSIGNED NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `identity_number` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- إرجاع أو استيراد بيانات الجدول `parents`
--

INSERT INTO `parents` (`parent_user_id`, `assigned_staff_user_id`, `created_at`, `identity_number`) VALUES
(3, 2, '2025-10-01 16:51:01', '');

--
-- القوادح `parents`
--
DELIMITER $$
CREATE TRIGGER `bi_parents_parent_role` BEFORE INSERT ON `parents` FOR EACH ROW BEGIN
  IF (SELECT role FROM users WHERE id = NEW.parent_user_id) <> 'Parent' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'parent_user_id must be a Parent user';
  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `bi_parents_staff_role` BEFORE INSERT ON `parents` FOR EACH ROW BEGIN
  IF (SELECT role FROM users WHERE id = NEW.assigned_staff_user_id) <> 'Staff' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'assigned_staff_user_id must be a Staff user';
  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `bu_parents_parent_role` BEFORE UPDATE ON `parents` FOR EACH ROW BEGIN
  IF (SELECT role FROM users WHERE id = NEW.parent_user_id) <> 'Parent' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'parent_user_id must be a Parent user';
  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `bu_parents_staff_role` BEFORE UPDATE ON `parents` FOR EACH ROW BEGIN
  IF (SELECT role FROM users WHERE id = NEW.assigned_staff_user_id) <> 'Staff' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'assigned_staff_user_id must be a Staff user';
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- بنية الجدول `users`
--

CREATE TABLE `users` (
  `id` int(10) UNSIGNED NOT NULL,
  `name` varchar(120) NOT NULL,
  `email` varchar(190) NOT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `role` enum('Admin','Staff','Parent') NOT NULL,
  `password` varchar(255) NOT NULL,
  `must_change_password` tinyint(1) NOT NULL DEFAULT 0,
  `employee_number` varchar(10) DEFAULT NULL,
  `identity_number` varchar(20) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ;

--
-- إرجاع أو استيراد بيانات الجدول `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `phone`, `role`, `password`, `must_change_password`, `employee_number`, `identity_number`, `created_at`) VALUES
(1, 'System Admin', 'admin@wethaq.com', '', 'Admin', 'admin123', 0, NULL, NULL, '2025-10-01 16:51:01'),
(2, 'Test Staff', 'staff@wethaq.com', '0550000000', 'Staff', '1234', 0, '1234', NULL, '2025-10-01 16:51:01'),
(3, 'Test Parent', 'parent@wethaq.com', '0551111111', 'Parent', '12345', 0, NULL, '54321', '2025-10-01 16:51:01'),
(4, 'Mohammedno', 'mohamedno@wethaq.com', '0509999999', 'Parent', 'v3mRxCsg', 0, NULL, NULL, '2025-10-01 16:51:56');

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
-- Indexes for table `children`
--
ALTER TABLE `children`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_children_parent` (`parent_user_id`);

--
-- Indexes for table `parents`
--
ALTER TABLE `parents`
  ADD PRIMARY KEY (`parent_user_id`),
  ADD KEY `idx_parents_staff` (`assigned_staff_user_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_users_email` (`email`),
  ADD KEY `idx_users_role` (`role`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `announcements`
--
ALTER TABLE `announcements`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `children`
--
ALTER TABLE `children`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- قيود الجداول المُلقاة.
--

--
-- قيود الجداول `announcements`
--
ALTER TABLE `announcements`
  ADD CONSTRAINT `fk_ann_parent` FOREIGN KEY (`parent_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ann_staff` FOREIGN KEY (`staff_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- قيود الجداول `children`
--
ALTER TABLE `children`
  ADD CONSTRAINT `fk_children_parent` FOREIGN KEY (`parent_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- قيود الجداول `parents`
--
ALTER TABLE `parents`
  ADD CONSTRAINT `fk_parents_staff` FOREIGN KEY (`assigned_staff_user_id`) REFERENCES `users` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_parents_user` FOREIGN KEY (`parent_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
