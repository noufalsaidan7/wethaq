TYPE=TRIGGERS
triggers='CREATE DEFINER=`root`@`localhost` TRIGGER `bi_children_parent_role`\nBEFORE INSERT ON `children` FOR EACH ROW\nBEGIN\n  IF (SELECT role FROM users WHERE id = NEW.parent_user_id) <> \'Parent\' THEN\n    SIGNAL SQLSTATE \'45000\' SET MESSAGE_TEXT = \'children.parent_user_id must reference a Parent user\';\n  END IF;\nEND' 'CREATE DEFINER=`root`@`localhost` TRIGGER `bu_children_parent_role`\nBEFORE UPDATE ON `children` FOR EACH ROW\nBEGIN\n  IF (SELECT role FROM users WHERE id = NEW.parent_user_id) <> \'Parent\' THEN\n    SIGNAL SQLSTATE \'45000\' SET MESSAGE_TEXT = \'children.parent_user_id must reference a Parent user\';\n  END IF;\nEND'
sql_modes=1077936128 1077936128
definers='root@localhost' 'root@localhost'
client_cs_names='utf8mb4' 'utf8mb4'
connection_cl_names='utf8mb4_unicode_ci' 'utf8mb4_unicode_ci'
db_cl_names='utf8mb4_unicode_ci' 'utf8mb4_unicode_ci'
created=1759337461525792 1759337461539268
