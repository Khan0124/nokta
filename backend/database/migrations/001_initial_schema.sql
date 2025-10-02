-- Migration: 001_initial_schema.sql
-- Description: Initial database schema with proper indexes and constraints
-- Date: 2025-01-08
-- Version: 1.0.0

-- ======================================
-- Database: nokta_pos
-- ======================================
CREATE DATABASE IF NOT EXISTS `nokta_pos` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `nokta_pos`;

-- ======================================
-- Table: tenants
-- ======================================
CREATE TABLE `tenants` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `domain` varchar(255) DEFAULT NULL,
  `logo` varchar(500) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `status` enum('active','suspended','cancelled') DEFAULT 'active',
  `subscription_plan` varchar(50) DEFAULT 'basic',
  `subscription_expires` datetime DEFAULT NULL,
  `settings` json DEFAULT NULL,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_tenants_domain` (`domain`),
  KEY `idx_tenants_status` (`status`),
  KEY `idx_tenants_subscription_plan` (`subscription_plan`),
  KEY `idx_tenants_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ======================================
-- Table: branches
-- ======================================
CREATE TABLE `branches` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tenant_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `code` varchar(50) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `opening_time` time DEFAULT NULL,
  `closing_time` time DEFAULT NULL,
  `is_main` tinyint(1) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1,
  `settings` json DEFAULT NULL,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_branches_tenant_id` (`tenant_id`),
  KEY `idx_branches_code` (`code`),
  KEY `idx_branches_is_active` (`is_active`),
  KEY `idx_branches_is_main` (`is_main`),
  KEY `idx_branches_location` (`latitude`, `longitude`),
  KEY `idx_branches_created_at` (`created_at`),
  CONSTRAINT `fk_branches_tenant_id` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ======================================
-- Table: users
-- ======================================
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tenant_id` int(11) NOT NULL,
  `branch_id` int(11) DEFAULT NULL,
  `username` varchar(50) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `full_name` varchar(255) NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `role` enum('customer','staff','manager','admin') DEFAULT 'customer',
  `is_active` tinyint(1) DEFAULT 1,
  `last_login` datetime DEFAULT NULL,
  `avatar` varchar(500) DEFAULT NULL,
  `permissions` json DEFAULT NULL,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_users_username_tenant` (`username`, `tenant_id`),
  UNIQUE KEY `uk_users_email_tenant` (`email`, `tenant_id`),
  KEY `idx_users_tenant_id` (`tenant_id`),
  KEY `idx_users_branch_id` (`branch_id`),
  KEY `idx_users_role` (`role`),
  KEY `idx_users_is_active` (`is_active`),
  KEY `idx_users_last_login` (`last_login`),
  KEY `idx_users_created_at` (`created_at`),
  CONSTRAINT `fk_users_tenant_id` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_users_branch_id` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ======================================
-- Table: categories
-- ======================================
CREATE TABLE `categories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tenant_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `image` varchar(500) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `sort_order` int(11) DEFAULT 0,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_categories_tenant_id` (`tenant_id`),
  KEY `idx_categories_parent_id` (`parent_id`),
  KEY `idx_categories_is_active` (`is_active`),
  KEY `idx_categories_sort_order` (`sort_order`),
  KEY `idx_categories_created_at` (`created_at`),
  CONSTRAINT `fk_categories_tenant_id` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_categories_parent_id` FOREIGN KEY (`parent_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ======================================
-- Table: products
-- ======================================
CREATE TABLE `products` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tenant_id` int(11) NOT NULL,
  `branch_id` int(11) NOT NULL,
  `category_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `sku` varchar(50) DEFAULT NULL,
  `barcode` varchar(100) DEFAULT NULL,
  `price` decimal(10,2) NOT NULL,
  `cost_price` decimal(10,2) DEFAULT NULL,
  `sale_price` decimal(10,2) DEFAULT NULL,
  `stock_quantity` int(11) DEFAULT 0,
  `min_stock_level` int(11) DEFAULT 0,
  `max_stock_level` int(11) DEFAULT NULL,
  `unit` varchar(20) DEFAULT 'piece',
  `is_active` tinyint(1) DEFAULT 1,
  `is_taxable` tinyint(1) DEFAULT 1,
  `tax_rate` decimal(5,2) DEFAULT 0.00,
  `images` json DEFAULT NULL,
  `attributes` json DEFAULT NULL,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_products_sku_tenant` (`sku`, `tenant_id`),
  UNIQUE KEY `uk_products_barcode_tenant` (`barcode`, `tenant_id`),
  KEY `idx_products_tenant_id` (`tenant_id`),
  KEY `idx_products_branch_id` (`branch_id`),
  KEY `idx_products_category_id` (`category_id`),
  KEY `idx_products_name` (`name`),
  KEY `idx_products_price` (`price`),
  KEY `idx_products_stock_quantity` (`stock_quantity`),
  KEY `idx_products_is_active` (`is_active`),
  KEY `idx_products_created_at` (`created_at`),
  FULLTEXT KEY `ft_products_search` (`name`, `description`),
  CONSTRAINT `fk_products_tenant_id` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_products_branch_id` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_products_category_id` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ======================================
-- Table: orders
-- ======================================
CREATE TABLE `orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tenant_id` int(11) NOT NULL,
  `branch_id` int(11) NOT NULL,
  `customer_id` int(11) DEFAULT NULL,
  `order_number` varchar(50) NOT NULL,
  `customer_name` varchar(255) DEFAULT NULL,
  `customer_phone` varchar(20) DEFAULT NULL,
  `customer_email` varchar(255) DEFAULT NULL,
  `subtotal` decimal(10,2) NOT NULL,
  `tax_amount` decimal(10,2) DEFAULT 0.00,
  `discount_amount` decimal(10,2) DEFAULT 0.00,
  `delivery_fee` decimal(10,2) DEFAULT 0.00,
  `total_amount` decimal(10,2) NOT NULL,
  `payment_method` enum('cash','card','mobile_money','bank_transfer') NOT NULL,
  `payment_status` enum('pending','paid','failed','refunded') DEFAULT 'pending',
  `order_status` enum('pending','confirmed','preparing','ready','delivered','cancelled') DEFAULT 'pending',
  `notes` text DEFAULT NULL,
  `delivery_address` text DEFAULT NULL,
  `expected_delivery_time` datetime DEFAULT NULL,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_orders_order_number_tenant` (`order_number`, `tenant_id`),
  KEY `idx_orders_tenant_id` (`tenant_id`),
  KEY `idx_orders_branch_id` (`branch_id`),
  KEY `idx_orders_customer_id` (`customer_id`),
  KEY `idx_orders_order_number` (`order_number`),
  KEY `idx_orders_payment_status` (`payment_status`),
  KEY `idx_orders_order_status` (`order_status`),
  KEY `idx_orders_payment_method` (`payment_method`),
  KEY `idx_orders_total_amount` (`total_amount`),
  KEY `idx_orders_created_at` (`created_at`),
  KEY `idx_orders_expected_delivery_time` (`expected_delivery_time`),
  CONSTRAINT `fk_orders_tenant_id` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_orders_branch_id` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_orders_customer_id` FOREIGN KEY (`customer_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ======================================
-- Table: order_items
-- ======================================
CREATE TABLE `order_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `product_name` varchar(255) NOT NULL,
  `quantity` int(11) NOT NULL,
  `unit_price` decimal(10,2) NOT NULL,
  `discount` decimal(10,2) DEFAULT 0.00,
  `subtotal` decimal(10,2) NOT NULL,
  `notes` varchar(200) DEFAULT NULL,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_order_items_order_id` (`order_id`),
  KEY `idx_order_items_product_id` (`product_id`),
  KEY `idx_order_items_quantity` (`quantity`),
  KEY `idx_order_items_unit_price` (`unit_price`),
  CONSTRAINT `fk_order_items_order_id` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_order_items_product_id` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ======================================
-- Table: payments
-- ======================================
CREATE TABLE `payments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL,
  `tenant_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `payment_method` enum('cash','card','mobile_money','bank_transfer') NOT NULL,
  `payment_status` enum('pending','completed','failed','refunded') NOT NULL,
  `transaction_id` varchar(255) DEFAULT NULL,
  `gateway_response` json DEFAULT NULL,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_payments_order_id` (`order_id`),
  KEY `idx_payments_tenant_id` (`tenant_id`),
  KEY `idx_payments_payment_method` (`payment_method`),
  KEY `idx_payments_payment_status` (`payment_status`),
  KEY `idx_payments_transaction_id` (`transaction_id`),
  KEY `idx_payments_created_at` (`created_at`),
  CONSTRAINT `fk_payments_order_id` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_payments_tenant_id` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ======================================
-- Table: inventory_transactions
-- ======================================
CREATE TABLE `inventory_transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tenant_id` int(11) NOT NULL,
  `branch_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `transaction_type` enum('in','out','adjustment','transfer') NOT NULL,
  `quantity` int(11) NOT NULL,
  `previous_quantity` int(11) NOT NULL,
  `new_quantity` int(11) NOT NULL,
  `reference_type` enum('order','purchase','return','adjustment','transfer') DEFAULT NULL,
  `reference_id` int(11) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_by` int(11) NOT NULL,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_inventory_transactions_tenant_id` (`tenant_id`),
  KEY `idx_inventory_transactions_branch_id` (`branch_id`),
  KEY `idx_inventory_transactions_product_id` (`product_id`),
  KEY `idx_inventory_transactions_transaction_type` (`transaction_type`),
  KEY `idx_inventory_transactions_reference_type` (`reference_type`),
  KEY `idx_inventory_transactions_reference_id` (`reference_id`),
  KEY `idx_inventory_transactions_created_by` (`created_by`),
  KEY `idx_inventory_transactions_created_at` (`created_at`),
  CONSTRAINT `fk_inventory_transactions_tenant_id` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_inventory_transactions_branch_id` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_inventory_transactions_product_id` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_inventory_transactions_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ======================================
-- Table: audit_logs
-- ======================================
CREATE TABLE `audit_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tenant_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `action` varchar(100) NOT NULL,
  `resource_type` varchar(100) NOT NULL,
  `resource_id` int(11) DEFAULT NULL,
  `old_values` json DEFAULT NULL,
  `new_values` json DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_audit_logs_tenant_id` (`tenant_id`),
  KEY `idx_audit_logs_user_id` (`user_id`),
  KEY `idx_audit_logs_action` (`action`),
  KEY `idx_audit_logs_resource_type` (`resource_type`),
  KEY `idx_audit_logs_resource_id` (`resource_id`),
  KEY `idx_audit_logs_created_at` (`created_at`),
  CONSTRAINT `fk_audit_logs_tenant_id` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_audit_logs_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ======================================
-- Table: system_settings
-- ======================================
CREATE TABLE `system_settings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tenant_id` int(11) DEFAULT NULL,
  `setting_key` varchar(100) NOT NULL,
  `setting_value` text NOT NULL,
  `setting_type` enum('string','number','boolean','json') DEFAULT 'string',
  `description` text DEFAULT NULL,
  `is_public` tinyint(1) DEFAULT 0,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_system_settings_key_tenant` (`setting_key`, `tenant_id`),
  KEY `idx_system_settings_tenant_id` (`tenant_id`),
  KEY `idx_system_settings_is_public` (`is_public`),
  CONSTRAINT `fk_system_settings_tenant_id` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ======================================
-- Insert default system settings
-- ======================================
INSERT INTO `system_settings` (`setting_key`, `setting_value`, `setting_type`, `description`, `is_public`) VALUES
('app_name', 'Nokta POS', 'string', 'Application name', 1),
('app_version', '1.0.0', 'string', 'Application version', 1),
('default_currency', 'USD', 'string', 'Default currency code', 1),
('default_timezone', 'UTC', 'string', 'Default timezone', 1),
('max_file_size', '10485760', 'number', 'Maximum file upload size in bytes', 1),
('allowed_file_types', '["image/jpeg","image/png","image/gif","image/webp","application/pdf"]', 'json', 'Allowed file types for uploads', 1),
('session_timeout', '3600', 'number', 'Session timeout in seconds', 0),
('max_login_attempts', '5', 'number', 'Maximum login attempts before lockout', 0),
('lockout_duration', '900', 'number', 'Account lockout duration in seconds', 0);

-- ======================================
-- Create indexes for better performance
-- ======================================

-- Composite indexes for common queries
CREATE INDEX `idx_products_tenant_category_active` ON `products` (`tenant_id`, `category_id`, `is_active`);
CREATE INDEX `idx_orders_tenant_branch_status` ON `orders` (`tenant_id`, `branch_id`, `order_status`);
CREATE INDEX `idx_orders_tenant_customer_date` ON `orders` (`tenant_id`, `customer_id`, `created_at`);
CREATE INDEX `idx_users_tenant_role_active` ON `users` (`tenant_id`, `role`, `is_active`);
CREATE INDEX `idx_inventory_tenant_branch_product` ON `inventory_transactions` (`tenant_id`, `branch_id`, `product_id`);

-- Partial indexes for better performance
CREATE INDEX `idx_products_active_stock` ON `products` (`is_active`, `stock_quantity`) WHERE `is_active` = 1;
CREATE INDEX `idx_orders_pending_delivery` ON `orders` (`order_status`, `expected_delivery_time`) WHERE `order_status` IN ('pending', 'confirmed', 'preparing');

-- ======================================
-- Create views for common queries
-- ======================================

-- View for product inventory summary
CREATE VIEW `v_product_inventory` AS
SELECT 
  p.id,
  p.tenant_id,
  p.branch_id,
  p.category_id,
  p.name,
  p.sku,
  p.barcode,
  p.price,
  p.stock_quantity,
  p.min_stock_level,
  p.max_stock_level,
  p.is_active,
  c.name as category_name,
  b.name as branch_name,
  CASE 
    WHEN p.stock_quantity <= p.min_stock_level THEN 'low_stock'
    WHEN p.stock_quantity = 0 THEN 'out_of_stock'
    ELSE 'in_stock'
  END as stock_status
FROM products p
JOIN categories c ON p.category_id = c.id
JOIN branches b ON p.branch_id = b.id
WHERE p.is_active = 1;

-- View for order summary
CREATE VIEW `v_order_summary` AS
SELECT 
  o.id,
  o.tenant_id,
  o.branch_id,
  o.order_number,
  o.customer_name,
  o.customer_phone,
  o.customer_email,
  o.total_amount,
  o.payment_status,
  o.order_status,
  o.payment_method,
  o.created_at,
  b.name as branch_name,
  COUNT(oi.id) as item_count,
  SUM(oi.quantity) as total_quantity
FROM orders o
JOIN branches b ON o.branch_id = b.id
LEFT JOIN order_items oi ON o.id = oi.order_id
GROUP BY o.id;

-- ======================================
-- Create stored procedures
-- ======================================

DELIMITER //

-- Procedure to update product stock
CREATE PROCEDURE `sp_update_product_stock`(
  IN p_product_id INT,
  IN p_quantity_change INT,
  IN p_transaction_type ENUM('in','out','adjustment','transfer'),
  IN p_reference_type ENUM('order','purchase','return','adjustment','transfer'),
  IN p_reference_id INT,
  IN p_notes TEXT,
  IN p_user_id INT
)
BEGIN
  DECLARE v_tenant_id INT;
  DECLARE v_branch_id INT;
  DECLARE v_current_quantity INT;
  DECLARE v_new_quantity INT;
  DECLARE v_transaction_id INT;
  
  -- Get product details
  SELECT tenant_id, branch_id, stock_quantity 
  INTO v_tenant_id, v_branch_id, v_current_quantity
  FROM products 
  WHERE id = p_product_id;
  
  -- Calculate new quantity
  SET v_new_quantity = v_current_quantity + p_quantity_change;
  
  -- Update product stock
  UPDATE products 
  SET stock_quantity = v_new_quantity, updated_at = NOW()
  WHERE id = p_product_id;
  
  -- Create inventory transaction record
  INSERT INTO inventory_transactions (
    tenant_id, branch_id, product_id, transaction_type, 
    quantity, previous_quantity, new_quantity, 
    reference_type, reference_id, notes, created_by
  ) VALUES (
    v_tenant_id, v_branch_id, p_product_id, p_transaction_type,
    p_quantity_change, v_current_quantity, v_new_quantity,
    p_reference_type, p_reference_id, p_notes, p_user_id
  );
  
  SET v_transaction_id = LAST_INSERT_ID();
  
  -- Return transaction details
  SELECT v_transaction_id as transaction_id, v_new_quantity as new_stock_quantity;
END //

-- Procedure to get low stock products
CREATE PROCEDURE `sp_get_low_stock_products`(
  IN p_tenant_id INT,
  IN p_branch_id INT DEFAULT NULL
)
BEGIN
  SELECT 
    p.id,
    p.name,
    p.sku,
    p.stock_quantity,
    p.min_stock_level,
    p.max_stock_level,
    c.name as category_name,
    b.name as branch_name
  FROM products p
  JOIN categories c ON p.category_id = c.id
  JOIN branches b ON p.branch_id = b.id
  WHERE p.tenant_id = p_tenant_id
    AND (p_branch_id IS NULL OR p.branch_id = p_branch_id)
    AND p.is_active = 1
    AND p.stock_quantity <= p.min_stock_level
  ORDER BY p.stock_quantity ASC;
END //

DELIMITER ;

-- ======================================
-- Create triggers
-- ======================================

-- Trigger to update product stock when order items are created
DELIMITER //
CREATE TRIGGER `tr_order_items_after_insert` 
AFTER INSERT ON `order_items`
FOR EACH ROW
BEGIN
  -- Update product stock
  UPDATE products 
  SET stock_quantity = stock_quantity - NEW.quantity,
      updated_at = NOW()
  WHERE id = NEW.product_id;
END //

-- Trigger to update product stock when order items are deleted
CREATE TRIGGER `tr_order_items_after_delete` 
AFTER DELETE ON `order_items`
FOR EACH ROW
BEGIN
  -- Restore product stock
  UPDATE products 
  SET stock_quantity = stock_quantity + OLD.quantity,
      updated_at = NOW()
  WHERE id = OLD.product_id;
END //

-- Trigger to update product stock when order items are updated
CREATE TRIGGER `tr_order_items_after_update` 
AFTER UPDATE ON `order_items`
FOR EACH ROW
BEGIN
  -- Update product stock based on quantity change
  UPDATE products 
  SET stock_quantity = stock_quantity + OLD.quantity - NEW.quantity,
      updated_at = NOW()
  WHERE id = NEW.product_id;
END //

DELIMITER ;

-- ======================================
-- Grant permissions
-- ======================================
GRANT SELECT, INSERT, UPDATE, DELETE ON `nokta_pos`.* TO 'nokta_user'@'%';
GRANT EXECUTE ON PROCEDURE `nokta_pos`.`sp_update_product_stock` TO 'nokta_user'@'%';
GRANT EXECUTE ON PROCEDURE `nokta_pos`.`sp_get_low_stock_products` TO 'nokta_user'@'%';

-- ======================================
-- Migration completed
-- ======================================
