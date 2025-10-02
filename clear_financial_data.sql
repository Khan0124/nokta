-- سكريبت حذف جميع المعاملات المالية والعمليات من الخزنة والتحويلات
-- Clear Financial Data Script for Nokta POS System

-- تعطيل فحص المفاتيح الأجنبية مؤقتاً
SET FOREIGN_KEY_CHECKS = 0;

-- حذف جميع المدفوعات
DELETE FROM payments;

-- حذف جميع عناصر الطلبات
DELETE FROM order_items;

-- حذف جميع الطلبات
DELETE FROM orders;

-- حذف جميع معاملات المخزون
DELETE FROM inventory_transactions;

-- حذف جميع سجلات التدقيق المتعلقة بالمعاملات المالية
DELETE FROM audit_logs WHERE resource_type IN ('order', 'payment', 'inventory_transaction');

-- إعادة تعيين العدادات التلقائية
ALTER TABLE payments AUTO_INCREMENT = 1;
ALTER TABLE order_items AUTO_INCREMENT = 1;
ALTER TABLE orders AUTO_INCREMENT = 1;
ALTER TABLE inventory_transactions AUTO_INCREMENT = 1;

-- إعادة تفعيل فحص المفاتيح الأجنبية
SET FOREIGN_KEY_CHECKS = 1;

-- عرض رسالة تأكيد
SELECT 'تم حذف جميع المعاملات المالية بنجاح' AS message;
