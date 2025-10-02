const mysql = require('mysql2/promise');
const config = require('./config/database');

async function clearFinancialData() {
  let connection;
  
  try {
    console.log('🔗 الاتصال بقاعدة البيانات...');
    connection = await mysql.createConnection(config);
    
    console.log('✅ تم الاتصال بقاعدة البيانات بنجاح');
    
    // تعطيل فحص المفاتيح الأجنبية
    await connection.execute('SET FOREIGN_KEY_CHECKS = 0');
    
    console.log('🗑️ بدء حذف البيانات المالية...');
    
    // حذف جميع المدفوعات
    const [paymentsResult] = await connection.execute('DELETE FROM payments');
    console.log(`✅ تم حذف ${paymentsResult.affectedRows} من المدفوعات`);
    
    // حذف جميع عناصر الطلبات
    const [orderItemsResult] = await connection.execute('DELETE FROM order_items');
    console.log(`✅ تم حذف ${orderItemsResult.affectedRows} من عناصر الطلبات`);
    
    // حذف جميع الطلبات
    const [ordersResult] = await connection.execute('DELETE FROM orders');
    console.log(`✅ تم حذف ${ordersResult.affectedRows} من الطلبات`);
    
    // حذف جميع معاملات المخزون
    const [inventoryResult] = await connection.execute('DELETE FROM inventory_transactions');
    console.log(`✅ تم حذف ${inventoryResult.affectedRows} من معاملات المخزون`);
    
    // حذف سجلات التدقيق المتعلقة بالمعاملات المالية
    const [auditResult] = await connection.execute(
      'DELETE FROM audit_logs WHERE resource_type IN (?, ?, ?)',
      ['order', 'payment', 'inventory_transaction']
    );
    console.log(`✅ تم حذف ${auditResult.affectedRows} من سجلات التدقيق`);
    
    // إعادة تعيين العدادات التلقائية
    await connection.execute('ALTER TABLE payments AUTO_INCREMENT = 1');
    await connection.execute('ALTER TABLE order_items AUTO_INCREMENT = 1');
    await connection.execute('ALTER TABLE orders AUTO_INCREMENT = 1');
    await connection.execute('ALTER TABLE inventory_transactions AUTO_INCREMENT = 1');
    console.log('✅ تم إعادة تعيين العدادات التلقائية');
    
    // إعادة تفعيل فحص المفاتيح الأجنبية
    await connection.execute('SET FOREIGN_KEY_CHECKS = 1');
    
    console.log('\n🎉 تم حذف جميع البيانات المالية بنجاح!');
    console.log('📊 ملخص العملية:');
    console.log(`   - المدفوعات: ${paymentsResult.affectedRows}`);
    console.log(`   - عناصر الطلبات: ${orderItemsResult.affectedRows}`);
    console.log(`   - الطلبات: ${ordersResult.affectedRows}`);
    console.log(`   - معاملات المخزون: ${inventoryResult.affectedRows}`);
    console.log(`   - سجلات التدقيق: ${auditResult.affectedRows}`);
    
  } catch (error) {
    console.error('❌ حدث خطأ أثناء حذف البيانات:', error.message);
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
      console.log('🔌 تم إغلاق الاتصال بقاعدة البيانات');
    }
  }
}

// تشغيل السكريبت
if (require.main === module) {
  clearFinancialData();
}

module.exports = clearFinancialData;
