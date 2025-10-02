// lib/services/sync_service.dart

class SyncService {
  static Future<void> syncAll() async {
    await _syncProducts();
    await _syncOrders();
  }

  static Future<void> _syncProducts() async {
    // TODO: Implement product sync logic
    print('Syncing products...');
  }

  static Future<void> _syncOrders() async {
    // TODO: Implement order sync logic
    print('Syncing orders...');
  }
}
