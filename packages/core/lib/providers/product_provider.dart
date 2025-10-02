import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/products_query.dart';
import '../services/product_service.dart';
import '../db/local_db.dart';

// Products Provider
final productsProvider = FutureProvider.family<List<Product>, ProductsQuery>(
  (ref, query) async {
    try {
      // First try to get from local database
      final localDb = LocalDB.instance;
      final localProducts = await localDb.getProducts(
        categoryId: query.categoryId,
        isAvailable: query.isAvailable,
        searchQuery: query.searchQuery,
      );
      
      if (localProducts.isNotEmpty) {
        // Also trigger background sync - removed syncProducts call since it doesn't exist
        return localProducts;
      }
      
      // If no local data, fetch from API
      final service = ref.read(productServiceProvider);
      return await service.getProducts(
        tenantId: 1, // Default tenant ID
        categoryId: query.categoryId,
        search: query.searchQuery,
        limit: query.limit,
      );
    } catch (e) {
      // Fallback to local data on error
      final localDb = LocalDB.instance;
      return await localDb.getProducts(
        categoryId: query.categoryId,
        isAvailable: query.isAvailable,
        searchQuery: query.searchQuery,
      );
    }
  },
);

// Single Product Provider
final productProvider = FutureProvider.family<Product?, int>(
  (ref, productId) async {
    try {
      // First check local database
      final localDb = LocalDB.instance;
      final localProduct = await localDb.getProduct(productId);
      if (localProduct != null) {
        return localProduct;
      }
      
      // Fetch from API
      final service = ref.read(productServiceProvider);
      return await service.getProduct(productId);
    } catch (e) {
      final localDb = LocalDB.instance;
      return await localDb.getProduct(productId);
    }
  },
);

// Featured Products Provider
final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  final query = ProductsQuery(isAvailable: true, limit: 10);
  final products = await ref.watch(productsProvider(query).future);
  
  // Return first 5 available products as featured
  return products.take(5).toList();
});

// Product Search Provider
final productSearchProvider = StateNotifierProvider<ProductSearchNotifier, String>((ref) {
  return ProductSearchNotifier();
});

class ProductSearchNotifier extends StateNotifier<String> {
  ProductSearchNotifier() : super('');
  
  void updateSearch(String query) {
    state = query;
  }
  
  void clearSearch() {
    state = '';
  }
}

// Filtered Products Provider
final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final searchQuery = ref.watch(productSearchProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  
  final query = ProductsQuery(
    categoryId: selectedCategory,
    searchQuery: searchQuery.isEmpty ? null : searchQuery,
    isAvailable: true,
  );
  
  return ref.watch(productsProvider(query));
});

// Selected Category Provider
final selectedCategoryProvider = StateProvider<int?>((ref) => null);

// Product Inventory Provider
final productInventoryProvider = FutureProvider.family<int?, int>(
  (ref, productId) async {
    try {
      // For now, return null since getProductStock doesn't exist
      // TODO: Implement stock tracking
      return null;
    } catch (e) {
      return null;
    }
  },
);

// Product Analytics Provider
final productAnalyticsProvider = FutureProvider.family<ProductAnalytics?, int>(
  (ref, productId) async {
    try {
      final service = ref.read(productServiceProvider);
      // For now, return null since getProductAnalytics doesn't exist
      // TODO: Implement analytics
      return null;
    } catch (e) {
      return null;
    }
  },
);

// Product Modifiers Provider
final productModifiersProvider = FutureProvider.family<List<ProductModifier>, int>(
  (ref, productId) async {
    try {
      final service = ref.read(productServiceProvider);
      // For now, return empty list since getProductModifiers doesn't exist
      // TODO: Implement modifiers
      return [];
    } catch (e) {
      return [];
    }
  },
);

// Analytics Model
class ProductAnalytics {
  final int productId;
  final int totalSold;
  final double revenue;
  final double averageRating;
  final int reviewCount;
  
  ProductAnalytics({
    required this.productId,
    required this.totalSold,
    required this.revenue,
    required this.averageRating,
    required this.reviewCount,
  });
}

// Product Modifier Model
class ProductModifier {
  final int id;
  final String groupName;
  final String name;
  final double price;
  final String type;
  final bool isRequired;
  final int minSelection;
  final int? maxSelection;
  
  ProductModifier({
    required this.id,
    required this.groupName,
    required this.name,
    required this.price,
    required this.type,
    required this.isRequired,
    required this.minSelection,
    this.maxSelection,
  });
}
