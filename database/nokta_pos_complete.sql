-- Nokta POS SaaS Database Schema
-- Version: 1.0.0
-- Date: 2025-01-08

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

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
  UNIQUE KEY `domain` (`domain`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
  KEY `tenant_id` (`tenant_id`),
  FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ======================================
-- Table: users
-- ======================================
CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tenant_id` int(11) DEFAULT NULL,
  `branch_id` int(11) DEFAULT NULL,
  `username` varchar(150) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `full_name` varchar(255) NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `role` enum('customer','staff','manager','admin') DEFAULT 'staff',
  `permissions` json DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `last_login` timestamp NULL DEFAULT NULL,
  `metadata` json DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_user_username` (`tenant_id`, `username`),
  UNIQUE KEY `uniq_user_email` (`tenant_id`, `email`),
  KEY `idx_user_tenant` (`tenant_id`),
  KEY `idx_user_branch` (`branch_id`),
  CONSTRAINT `fk_user_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_user_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Continue with all other tables...
-- [Rest of the SQL content from previous message]

CREATE TABLE IF NOT EXISTS `customers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tenant_id` int(11) NOT NULL,
  `full_name` varchar(255) NOT NULL,
  `phone` varchar(20) NOT NULL,
  `alternate_phone` varchar(20) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `preferred_branch_id` int(11) DEFAULT NULL,
  `default_address_id` int(11) DEFAULT NULL,
  `preferred_language` varchar(10) DEFAULT 'ar',
  `loyalty_points` int(11) DEFAULT 0,
  `last_order_at` timestamp NULL DEFAULT NULL,
  `metadata` json DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_customer_phone` (`tenant_id`, `phone`),
  KEY `idx_customer_tenant` (`tenant_id`),
  KEY `idx_customer_branch` (`preferred_branch_id`),
  CONSTRAINT `fk_customer_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_customer_branch` FOREIGN KEY (`preferred_branch_id`) REFERENCES `branches` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `customer_addresses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `customer_id` int(11) NOT NULL,
  `label` varchar(100) DEFAULT NULL,
  `address_line1` varchar(255) NOT NULL,
  `address_line2` varchar(255) DEFAULT NULL,
  `city` varchar(120) DEFAULT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `is_default` tinyint(1) DEFAULT 0,
  `notes` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_customer_address_customer` (`customer_id`),
  CONSTRAINT `fk_customer_address_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `customers`
  ADD CONSTRAINT `fk_customer_default_address`
  FOREIGN KEY (`default_address_id`) REFERENCES `customer_addresses` (`id`) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS `orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tenant_id` int(11) NOT NULL,
  `branch_id` int(11) DEFAULT NULL,
  `order_number` varchar(50) NOT NULL,
  `source` enum('pos','customer_app','call_center','driver_app','admin') DEFAULT 'pos',
  `status` enum('pending','confirmed','preparing','ready','on_way','delivered','cancelled') DEFAULT 'pending',
  `payment_status` enum('pending','paid','failed','refunded') DEFAULT 'pending',
  `payment_method` enum('cash','card','mobile_money','bank_transfer','wallet') DEFAULT 'cash',
  `subtotal_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `discount_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `tax_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `delivery_fee` decimal(10,2) NOT NULL DEFAULT 0.00,
  `total_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `customer_id` int(11) DEFAULT NULL,
  `customer_name` varchar(255) DEFAULT NULL,
  `customer_phone` varchar(20) DEFAULT NULL,
  `customer_email` varchar(255) DEFAULT NULL,
  `delivery_address` varchar(255) DEFAULT NULL,
  `delivery_city` varchar(120) DEFAULT NULL,
  `delivery_latitude` decimal(10,8) DEFAULT NULL,
  `delivery_longitude` decimal(11,8) DEFAULT NULL,
  `delivery_type` enum('delivery','pickup') DEFAULT 'delivery',
  `delivery_notes` varchar(500) DEFAULT NULL,
  `scheduled_at` timestamp NULL DEFAULT NULL,
  `metadata` json DEFAULT NULL,
  `campaign_code` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_order_number` (`tenant_id`, `order_number`),
  KEY `idx_orders_tenant` (`tenant_id`),
  KEY `idx_orders_branch` (`branch_id`),
  KEY `idx_orders_customer` (`customer_id`),
  KEY `idx_orders_phone` (`customer_phone`),
  CONSTRAINT `fk_orders_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_orders_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_orders_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `order_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL,
  `product_id` int(11) DEFAULT NULL,
  `product_name` varchar(255) NOT NULL,
  `quantity` int(11) NOT NULL DEFAULT 1,
  `unit_price` decimal(10,2) NOT NULL DEFAULT 0.00,
  `discount_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `modifiers` json DEFAULT NULL,
  `notes` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_order_items_order` (`order_id`),
  CONSTRAINT `fk_order_items_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `call_center_calls` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tenant_id` int(11) NOT NULL,
  `branch_id` int(11) DEFAULT NULL,
  `agent_id` int(11) DEFAULT NULL,
  `customer_id` int(11) DEFAULT NULL,
  `order_id` int(11) DEFAULT NULL,
  `phone` varchar(20) NOT NULL,
  `status` enum('queued','active','completed','abandoned','scheduled') DEFAULT 'queued',
  `disposition` enum('completed','callback','voicemail','abandoned','spam','wrong_number') DEFAULT 'completed',
  `wait_time_seconds` int(11) DEFAULT 0,
  `handle_time_seconds` int(11) DEFAULT 0,
  `notes` varchar(1000) DEFAULT NULL,
  `metadata` json DEFAULT NULL,
  `started_at` timestamp NULL DEFAULT NULL,
  `ended_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_call_center_calls_tenant` (`tenant_id`),
  KEY `idx_call_center_calls_branch` (`branch_id`),
  KEY `idx_call_center_calls_phone` (`phone`),
  KEY `idx_call_center_calls_order` (`order_id`),
  CONSTRAINT `fk_call_center_calls_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_call_center_calls_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_call_center_calls_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_call_center_calls_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `call_center_queue_events` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tenant_id` int(11) NOT NULL,
  `call_id` int(11) DEFAULT NULL,
  `phone` varchar(20) NOT NULL,
  `event_type` enum('queued','assigned','completed','abandoned','callback_scheduled') NOT NULL,
  `agent_id` int(11) DEFAULT NULL,
  `notes` varchar(500) DEFAULT NULL,
  `metadata` json DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_call_queue_tenant` (`tenant_id`),
  KEY `idx_call_queue_call` (`call_id`),
  CONSTRAINT `fk_call_queue_call` FOREIGN KEY (`call_id`) REFERENCES `call_center_calls` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_call_queue_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `driver_tasks` (
  `id` varchar(64) NOT NULL,
  `driver_id` varchar(64) NOT NULL,
  `order_id` int(11) NOT NULL,
  `tenant_id` int(11) DEFAULT NULL,
  `branch_id` int(11) DEFAULT NULL,
  `customer_name` varchar(255) NOT NULL,
  `customer_phone` varchar(20) NOT NULL,
  `dropoff_address` varchar(255) NOT NULL,
  `dropoff_latitude` decimal(10,8) NOT NULL,
  `dropoff_longitude` decimal(11,8) NOT NULL,
  `amount_due` decimal(10,2) NOT NULL DEFAULT 0.00,
  `currency` varchar(8) NOT NULL DEFAULT 'SAR',
  `status` enum('assigned','accepted','pickedUp','enRoute','delivered','failed','cancelled') NOT NULL DEFAULT 'assigned',
  `requires_collection` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `picked_at` timestamp NULL DEFAULT NULL,
  `en_route_at` timestamp NULL DEFAULT NULL,
  `delivered_at` timestamp NULL DEFAULT NULL,
  `cancelled_at` timestamp NULL DEFAULT NULL,
  `failed_at` timestamp NULL DEFAULT NULL,
  `payment_method` enum('cash','card','wallet','bankTransfer') DEFAULT NULL,
  `collected_amount` decimal(10,2) DEFAULT NULL,
  `notes` varchar(1000) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_driver_tasks_driver` (`driver_id`),
  KEY `idx_driver_tasks_order` (`order_id`),
  KEY `idx_driver_tasks_status` (`status`),
  CONSTRAINT `fk_driver_tasks_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_driver_tasks_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_driver_tasks_branch` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `driver_route_points` (
  `id` varchar(64) NOT NULL,
  `task_id` varchar(64) NOT NULL,
  `latitude` decimal(10,8) NOT NULL,
  `longitude` decimal(11,8) NOT NULL,
  `recorded_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `speed_kph` decimal(10,2) NOT NULL DEFAULT 0.00,
  `accuracy_meters` decimal(10,2) DEFAULT NULL,
  `heading` decimal(10,2) DEFAULT NULL,
  `interval_seconds` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_route_task` (`task_id`),
  KEY `idx_route_recorded_at` (`recorded_at`),
  CONSTRAINT `fk_route_task` FOREIGN KEY (`task_id`) REFERENCES `driver_tasks` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `driver_settlements` (
  `id` varchar(64) NOT NULL,
  `driver_id` varchar(64) NOT NULL,
  `tenant_id` int(11) DEFAULT NULL,
  `shift_start` timestamp NOT NULL,
  `shift_end` timestamp NOT NULL,
  `total_assignments` int(11) NOT NULL DEFAULT 0,
  `completed_assignments` int(11) NOT NULL DEFAULT 0,
  `total_due` decimal(10,2) NOT NULL DEFAULT 0.00,
  `collected_cash` decimal(10,2) NOT NULL DEFAULT 0.00,
  `collected_non_cash` decimal(10,2) NOT NULL DEFAULT 0.00,
  `pending_remittance` decimal(10,2) NOT NULL DEFAULT 0.00,
  `generated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `notes` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_settlement_driver` (`driver_id`),
  KEY `idx_settlement_period` (`shift_start`,`shift_end`),
  CONSTRAINT `fk_settlement_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `subscription_plans` (
  `id` varchar(32) NOT NULL,
  `name` varchar(100) NOT NULL,
  `tier` varchar(32) NOT NULL,
  `currency` char(3) NOT NULL DEFAULT 'USD',
  `monthly_price` decimal(10,2) NOT NULL,
  `yearly_price` decimal(10,2) NOT NULL,
  `monthly_grace_days` int(11) NOT NULL DEFAULT 7,
  `yearly_grace_days` int(11) NOT NULL DEFAULT 14,
  `trial_days` int(11) DEFAULT NULL,
  `features` json DEFAULT NULL,
  `limits` json DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tenant_subscriptions` (
  `id` varchar(64) NOT NULL,
  `tenant_id` int(11) NOT NULL,
  `plan_id` varchar(32) NOT NULL,
  `status` varchar(32) NOT NULL DEFAULT 'active',
  `billing_cycle` varchar(16) NOT NULL,
  `seats` int(11) NOT NULL DEFAULT 1,
  `currency` char(3) NOT NULL DEFAULT 'USD',
  `payment_method` varchar(32) NOT NULL,
  `current_period_start` datetime NOT NULL,
  `current_period_end` datetime NOT NULL,
  `trial_ends_at` datetime DEFAULT NULL,
  `resume_at` datetime DEFAULT NULL,
  `cancel_at` datetime DEFAULT NULL,
  `notes` varchar(500) DEFAULT NULL,
  `meta` json DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_subscription_tenant` (`tenant_id`),
  KEY `idx_subscription_plan` (`plan_id`),
  CONSTRAINT `fk_subscription_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_subscription_plan` FOREIGN KEY (`plan_id`) REFERENCES `subscription_plans` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `subscription_invoices` (
  `id` varchar(64) NOT NULL,
  `subscription_id` varchar(64) NOT NULL,
  `invoice_number` varchar(64) NOT NULL,
  `period_start` datetime NOT NULL,
  `period_end` datetime NOT NULL,
  `issue_date` datetime NOT NULL,
  `due_date` datetime DEFAULT NULL,
  `currency` char(3) NOT NULL DEFAULT 'USD',
  `subtotal_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `tax_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `total_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `amount_paid` decimal(10,2) NOT NULL DEFAULT 0.00,
  `status` varchar(32) NOT NULL DEFAULT 'open',
  `pdf_path` varchar(255) DEFAULT NULL,
  `pdf_generated_at` datetime DEFAULT NULL,
  `line_items` json DEFAULT NULL,
  `notes` varchar(1000) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_invoice_number` (`invoice_number`),
  KEY `idx_invoice_subscription` (`subscription_id`),
  CONSTRAINT `fk_invoice_subscription` FOREIGN KEY (`subscription_id`) REFERENCES `tenant_subscriptions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `subscription_payments` (
  `id` varchar(64) NOT NULL,
  `invoice_id` varchar(64) NOT NULL,
  `provider` varchar(32) NOT NULL,
  `provider_reference` varchar(100) DEFAULT NULL,
  `amount` decimal(10,2) NOT NULL,
  `currency` char(3) NOT NULL DEFAULT 'USD',
  `status` varchar(32) NOT NULL DEFAULT 'pending',
  `paid_at` datetime DEFAULT NULL,
  `metadata` json DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_payment_invoice` (`invoice_id`),
  KEY `idx_payment_provider_reference` (`provider_reference`),
  CONSTRAINT `fk_payment_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `subscription_invoices` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ======================================
-- Table: tenant_onboarding_sessions
-- ======================================
CREATE TABLE IF NOT EXISTS `tenant_onboarding_sessions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `token` char(36) NOT NULL,
  `tenant_id` int(11) DEFAULT NULL,
  `company_name` varchar(255) NOT NULL,
  `contact_name` varchar(255) NOT NULL,
  `contact_email` varchar(255) NOT NULL,
  `contact_phone` varchar(20) NOT NULL,
  `preferred_language` varchar(10) DEFAULT 'ar',
  `subscription_plan` varchar(50) DEFAULT 'basic',
  `status` enum('draft','in_progress','ready','completed','cancelled','expired') DEFAULT 'in_progress',
  `current_step` varchar(50) DEFAULT 'company_profile',
  `expires_at` datetime NOT NULL,
  `metadata` json DEFAULT NULL,
  `completed_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_onboarding_token` (`token`),
  KEY `idx_onboarding_tenant` (`tenant_id`),
  KEY `idx_onboarding_status` (`status`),
  KEY `idx_onboarding_expires` (`expires_at`),
  CONSTRAINT `fk_onboarding_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ======================================
-- Table: tenant_onboarding_steps
-- ======================================
CREATE TABLE IF NOT EXISTS `tenant_onboarding_steps` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `session_id` int(11) NOT NULL,
  `step_key` varchar(100) NOT NULL,
  `status` enum('pending','in_progress','completed','skipped','error') DEFAULT 'pending',
  `display_order` tinyint(3) NOT NULL DEFAULT 1,
  `payload` json DEFAULT NULL,
  `completed_at` timestamp NULL DEFAULT NULL,
  `last_error` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_onboarding_step` (`session_id`, `step_key`),
  KEY `idx_onboarding_step_session` (`session_id`),
  CONSTRAINT `fk_onboarding_step_session` FOREIGN KEY (`session_id`) REFERENCES `tenant_onboarding_sessions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ======================================
-- Table: tenant_onboarding_events
-- ======================================
CREATE TABLE IF NOT EXISTS `tenant_onboarding_events` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `session_id` int(11) NOT NULL,
  `event_type` varchar(100) NOT NULL,
  `actor_type` varchar(50) DEFAULT 'system',
  `actor_identifier` varchar(255) DEFAULT NULL,
  `details` json DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_onboarding_event_session` (`session_id`),
  KEY `idx_onboarding_event_type` (`event_type`),
  CONSTRAINT `fk_onboarding_event_session` FOREIGN KEY (`session_id`) REFERENCES `tenant_onboarding_sessions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ======================================
-- Table: dynamic_price_adjustments
-- ======================================
CREATE TABLE IF NOT EXISTS `dynamic_price_adjustments` (
  `id` varchar(64) NOT NULL,
  `tenant_id` int(11) DEFAULT NULL,
  `name` varchar(120) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `type` enum('percentage','fixed','availability') NOT NULL DEFAULT 'percentage',
  `value` decimal(10,2) DEFAULT NULL,
  `fixed_price` decimal(10,2) DEFAULT NULL,
  `product_ids` json NOT NULL,
  `branch_ids` json DEFAULT NULL,
  `channels` json NOT NULL,
  `priority` int(11) NOT NULL DEFAULT 100,
  `stackable` tinyint(1) NOT NULL DEFAULT 0,
  `start_at` datetime DEFAULT NULL,
  `end_at` datetime DEFAULT NULL,
  `status` enum('scheduled','active','disabled','archived','expired') DEFAULT 'scheduled',
  `created_by` int(11) DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_dynamic_pricing_tenant` (`tenant_id`),
  KEY `idx_dynamic_pricing_status` (`status`),
  KEY `idx_dynamic_pricing_window` (`start_at`, `end_at`),
  CONSTRAINT `fk_dynamic_pricing_tenant` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ======================================
-- Table: dynamic_pricing_audit_events
-- ======================================
CREATE TABLE IF NOT EXISTS `dynamic_pricing_audit_events` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `adjustment_id` varchar(64) NOT NULL,
  `tenant_id` int(11) DEFAULT NULL,
  `event_type` varchar(50) NOT NULL,
  `actor_id` int(11) DEFAULT NULL,
  `actor_name` varchar(255) DEFAULT NULL,
  `details` json DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_dynamic_pricing_audit_adjustment` (`adjustment_id`),
  KEY `idx_dynamic_pricing_audit_tenant` (`tenant_id`),
  CONSTRAINT `fk_dynamic_pricing_audit_adjustment` FOREIGN KEY (`adjustment_id`) REFERENCES `dynamic_price_adjustments` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

