import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../models/user.dart';
import '../models/tenant.dart';

class LocalDB {
  static final LocalDB _instance = LocalDB._internal();
  static Database? _database;

  factory LocalDB() {
    return _instance;
  }

  LocalDB._internal();

  static LocalDB get instance => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'nokta_pos.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create tables
    await _createTables(db);
    
    // Insert initial data
    await _insertInitialData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < newVersion) {
      // Add new tables or modify existing ones
    }
  }

  Future<void> _createTables(Database db) async {
    // Products table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY,
        tenant_id INTEGER NOT NULL,
        category_id INTEGER,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        status TEXT NOT NULL,
        type TEXT NOT NULL,
        image TEXT,
        ingredients TEXT,
        allergens TEXT,
        nutritional_info TEXT,
        preparation_time INTEGER,
        is_vegetarian INTEGER,
        is_vegan INTEGER,
        is_gluten_free INTEGER,
        is_halal INTEGER,
        is_kosher INTEGER,
        is_featured INTEGER,
        sort_order INTEGER,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY,
        tenant_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL,
        image TEXT,
        color TEXT,
        icon TEXT,
        sort_order INTEGER,
        parent_id INTEGER,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Orders table
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY,
        tenant_id INTEGER NOT NULL,
        branch_id INTEGER NOT NULL,
        customer_id INTEGER NOT NULL,
        order_type TEXT NOT NULL,
        status TEXT NOT NULL,
        subtotal REAL NOT NULL,
        tax REAL NOT NULL,
        delivery_fee REAL NOT NULL,
        total REAL NOT NULL,
        payment_method TEXT,
        payment_status TEXT,
        driver_id INTEGER,
        delivery_address TEXT,
        scheduled_time TEXT,
        notes TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Order items table
    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        notes TEXT,
        created_at TEXT
      )
    ''');

    // Order item modifiers table
    await db.execute('''
      CREATE TABLE order_item_modifiers (
        id INTEGER PRIMARY KEY,
        order_item_id INTEGER NOT NULL,
        modifier_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        created_at TEXT
      )
    ''');

    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        tenant_id INTEGER NOT NULL,
        branch_id INTEGER NOT NULL,
        email TEXT NOT NULL,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        role TEXT NOT NULL,
        status TEXT NOT NULL,
        phone TEXT,
        avatar TEXT,
        date_of_birth TEXT,
        gender TEXT,
        address TEXT,
        city TEXT,
        state TEXT,
        country TEXT,
        postal_code TEXT,
        preferences TEXT,
        last_login_at TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Tenants table
    await db.execute('''
      CREATE TABLE tenants (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        domain TEXT NOT NULL,
        status TEXT NOT NULL,
        subscription_plan TEXT NOT NULL,
        subscription_expires TEXT,
        max_branches INTEGER,
        max_users INTEGER,
        max_products INTEGER,
        features TEXT,
        settings TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Cart items table (for offline cart)
    await db.execute('''
      CREATE TABLE cart_items (
        id INTEGER PRIMARY KEY,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        notes TEXT,
        special_instructions TEXT,
        created_at TEXT
      )
    ''');

    // Cart item modifiers table
    await db.execute('''
      CREATE TABLE cart_item_modifiers (
        id INTEGER PRIMARY KEY,
        cart_item_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_products_tenant_id ON products(tenant_id)');
    await db.execute('CREATE INDEX idx_products_category_id ON products(category_id)');
    await db.execute('CREATE INDEX idx_orders_tenant_id ON orders(tenant_id)');
    await db.execute('CREATE INDEX idx_orders_customer_id ON orders(customer_id)');
    await db.execute('CREATE INDEX idx_order_items_order_id ON order_items(order_id)');
    await db.execute('CREATE INDEX idx_users_tenant_id ON users(tenant_id)');
    await db.execute('CREATE INDEX idx_categories_tenant_id ON categories(tenant_id)');
  }

  Future<void> _insertInitialData(Database db) async {
    // Insert default tenant
    await db.insert('tenants', {
      'id': 1,
      'name': 'Default Tenant',
      'domain': 'default',
      'status': 'active',
      'subscription_plan': 'basic',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Insert default categories
    await db.insert('categories', {
      'id': 1,
      'tenant_id': 1,
      'name': 'Appetizers',
      'description': 'Start your meal with our delicious appetizers',
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    await db.insert('categories', {
      'id': 2,
      'tenant_id': 1,
      'name': 'Main Dishes',
      'description': 'Our signature main dishes',
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    await db.insert('categories', {
      'id': 3,
      'tenant_id': 1,
      'name': 'Beverages',
      'description': 'Refreshing drinks and beverages',
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    await db.insert('categories', {
      'id': 4,
      'tenant_id': 1,
      'name': 'Desserts',
      'description': 'Sweet endings to your meal',
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Product operations
  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getProducts({
    int? categoryId,
    bool? isAvailable,
    String? searchQuery,
  }) async {
    final db = await database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];
    
    if (categoryId != null) {
      whereClause += ' AND category_id = ?';
      whereArgs.add(categoryId);
    }
    
    if (isAvailable != null) {
      whereClause += ' AND status = ?';
      whereArgs.add(isAvailable ? 'active' : 'inactive');
    }
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause += ' AND (name LIKE ? OR description LIKE ?)';
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<Product?> getProduct(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Category operations
  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      orderBy: 'sort_order ASC, name ASC',
    );

    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<Category?> getCategory(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  // Order operations
  Future<int> insertOrder(Order order) async {
    final db = await database;
    
    // Insert order
    final orderId = await db.insert('orders', order.toMap());
    
    // Insert order items
    for (final item in order.items) {
      final orderItem = item.copyWith(
        id: 0,
        orderId: orderId,
      );
      await db.insert('order_items', orderItem.toMap());
      
      // Insert order item modifiers
      if (item.modifiers != null) {
        for (final modifier in item.modifiers!) {
          final orderItemModifier = modifier.copyWith(
            id: 0,
            orderItemId: orderItem.id,
          );
          await db.insert('order_item_modifiers', orderItemModifier.toMap());
        }
      }
    }
    
    return orderId;
  }

  Future<List<Order>> getOrders() async {
    final db = await database;
    final List<Map<String, dynamic>> orderMaps = await db.query(
      'orders',
      orderBy: 'created_at DESC',
    );

    final List<Order> orders = [];
    
    for (final orderMap in orderMaps) {
      final orderId = orderMap['id'] as int;
      
      // Get order items
      final List<Map<String, dynamic>> itemMaps = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );

      final List<OrderItem> items = [];
      
      for (final itemMap in itemMaps) {
        final itemId = itemMap['id'] as int;
        
        // Get item modifiers
        final List<Map<String, dynamic>> modifierMaps = await db.query(
          'order_item_modifiers',
          where: 'order_item_id = ?',
          whereArgs: [itemId],
        );

        final List<OrderItemModifier> modifiers = modifierMaps
            .map((m) => OrderItemModifier.fromMap(m))
            .toList();

        final item = OrderItem.fromMap({
          ...itemMap,
          'modifiers': modifiers,
        });
        
        items.add(item);
      }

      final order = Order.fromMap({
        ...orderMap,
        'items': items,
      });
      
      orders.add(order);
    }

    return orders;
  }

  Future<Order?> getOrder(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> orderMaps = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (orderMaps.isEmpty) return null;

    final orderMap = orderMaps.first;
    final orderId = orderMap['id'] as int;

    // Get order items
    final List<Map<String, dynamic>> itemMaps = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );

    final List<OrderItem> items = [];
    
    for (final itemMap in itemMaps) {
      final itemId = itemMap['id'] as int;
      
      // Get item modifiers
      final List<Map<String, dynamic>> modifierMaps = await db.query(
        'order_item_modifiers',
        where: 'order_item_id = ?',
        whereArgs: [itemId],
      );

      final List<OrderItemModifier> modifiers = modifierMaps
          .map((m) => OrderItemModifier.fromMap(m))
          .toList();

      final item = OrderItem.fromMap({
        ...itemMap,
        'modifiers': modifiers,
      });
      
      items.add(item);
    }

    return Order.fromMap({
      ...orderMap,
      'items': items,
    });
  }

  Future<int> updateOrder(Order order) async {
    final db = await database;
    return await db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<int> deleteOrder(int id) async {
    final db = await database;
    
    // Delete order item modifiers first
    final List<Map<String, dynamic>> itemMaps = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [id],
    );
    
    for (final itemMap in itemMaps) {
      final itemId = itemMap['id'] as int;
      await db.delete(
        'order_item_modifiers',
        where: 'order_item_id = ?',
        whereArgs: [itemId],
      );
    }
    
    // Delete order items
    await db.delete(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [id],
    );
    
    // Delete order
    return await db.delete(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // User operations
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<List<User>> getUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      orderBy: 'first_name ASC, last_name ASC',
    );

    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<User?> getUser(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Tenant operations
  Future<int> insertTenant(Tenant tenant) async {
    final db = await database;
    return await db.insert('tenants', tenant.toMap());
  }

  Future<List<Tenant>> getTenants() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tenants',
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => Tenant.fromMap(maps[i]));
  }

  Future<Tenant?> getTenant(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tenants',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Tenant.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateTenant(Tenant tenant) async {
    final db = await database;
    return await db.update(
      'tenants',
      tenant.toMap(),
      where: 'id = ?',
      whereArgs: [tenant.id],
    );
  }

  Future<int> deleteTenant(int id) async {
    final db = await database;
    return await db.delete(
      'tenants',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Cart operations (for offline cart)
  Future<int> insertCartItem(CartItem item) async {
    final db = await database;
    return await db.insert('cart_items', item.toMap());
  }

  Future<List<CartItem>> getCartItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cart_items',
      orderBy: 'created_at ASC',
    );

    final List<CartItem> items = [];
    
    for (final map in maps) {
      final productId = map['product_id'] as int;
      final product = await getProduct(productId);
      
      if (product != null) {
        final item = CartItem.fromMap({
          ...map,
          'product': product.toMap(),
        });
        items.add(item);
      }
    }

    return items;
  }

  Future<int> updateCartItem(CartItem item) async {
    final db = await database;
    return await db.update(
      'cart_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteCartItem(int id) async {
    final db = await database;
    return await db.delete(
      'cart_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearCart() async {
    final db = await database;
    await db.delete('cart_item_modifiers');
    await db.delete('cart_items');
  }

  // Database maintenance
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('order_item_modifiers');
    await db.delete('order_items');
    await db.delete('orders');
    await db.delete('cart_item_modifiers');
    await db.delete('cart_items');
    await db.delete('products');
    await db.delete('categories');
    await db.delete('users');
    await db.delete('tenants');
  }

  Future<int> getDatabaseSize() async {
    final db = await database;
    final result = await db.rawQuery('PRAGMA page_count');
    final pageCount = result.first['page_count'] as int;
    final result2 = await db.rawQuery('PRAGMA page_size');
    final pageSize = result2.first['page_size'] as int;
    return pageCount * pageSize;
  }

  Future<void> optimizeDatabase() async {
    final db = await database;
    await db.execute('VACUUM');
    await db.execute('ANALYZE');
  }
}
