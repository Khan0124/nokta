import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../models/product_analytics.dart';
import '../models/product_modifier.dart';
import '../providers/dio_provider.dart';

class ProductService {
  final Dio _dio;

  ProductService(this._dio);

  // Get all products for a tenant
  Future<List<Product>> getProducts({
    int? tenantId,
    int? categoryId,
    String? search,
    String? sortBy,
    String? sortOrder,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (tenantId != null) queryParams['tenant_id'] = tenantId;
      if (categoryId != null) queryParams['category_id'] = categoryId;
      if (search != null) queryParams['search'] = search;
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response =
          await _dio.get('/products', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => Product.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  // Get a single product by ID
  Future<Product> getProduct(int productId) async {
    try {
      final response = await _dio.get('/products/$productId');

      if (response.statusCode == 200) {
        return Product.fromMap(response.data);
      } else {
        throw Exception('Failed to load product');
      }
    } catch (e) {
      throw Exception('Error fetching product: $e');
    }
  }

  // Create a new product
  Future<Product> createProduct(Product product) async {
    try {
      final response = await _dio.post('/products', data: product.toMap());

      if (response.statusCode == 201) {
        return Product.fromMap(response.data);
      } else {
        throw Exception('Failed to create product');
      }
    } catch (e) {
      throw Exception('Error creating product: $e');
    }
  }

  // Update an existing product
  Future<Product> updateProduct(int productId, Product product) async {
    try {
      final response = await _dio.put(
        '/products/$productId',
        data: product.toMap(),
      );

      if (response.statusCode == 200) {
        return Product.fromMap(response.data);
      } else {
        throw Exception('Failed to update product');
      }
    } catch (e) {
      throw Exception('Error updating product: $e');
    }
  }

  // Delete a product
  Future<void> deleteProduct(int productId) async {
    try {
      final response = await _dio.delete('/products/$productId');

      if (response.statusCode != 204) {
        throw Exception('Failed to delete product');
      }
    } catch (e) {
      throw Exception('Error deleting product: $e');
    }
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(int categoryId) async {
    try {
      final response = await _dio.get('/categories/$categoryId/products');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => Product.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load products by category');
      }
    } catch (e) {
      throw Exception('Error fetching products by category: $e');
    }
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    try {
      final response =
          await _dio.get('/products/search', queryParameters: {'q': query});

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => Product.fromMap(json)).toList();
      } else {
        throw Exception('Failed to search products');
      }
    } catch (e) {
      throw Exception('Error searching products: $e');
    }
  }

  // Get featured products
  Future<List<Product>> getFeaturedProducts({int? tenantId}) async {
    try {
      final queryParams = <String, dynamic>{'featured': true};
      if (tenantId != null) queryParams['tenant_id'] = tenantId;

      final response =
          await _dio.get('/products', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => Product.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load featured products');
      }
    } catch (e) {
      throw Exception('Error fetching featured products: $e');
    }
  }

  // Get product modifiers
  Future<List<ProductModifier>> getProductModifiers(int productId) async {
    try {
      final response = await _dio.get('/products/$productId/modifiers');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => ProductModifier.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load product modifiers');
      }
    } catch (e) {
      throw Exception('Error fetching product modifiers: $e');
    }
  }

  // Get product analytics
  Future<ProductAnalytics> getProductAnalytics(int productId) async {
    try {
      final response = await _dio.get('/products/$productId/analytics');

      if (response.statusCode == 200) {
        return ProductAnalytics.fromMap(response.data);
      } else {
        throw Exception('Failed to load product analytics');
      }
    } catch (e) {
      throw Exception('Error fetching product analytics: $e');
    }
  }

  // Upload product image
  Future<String> uploadProductImage(int productId, File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imageFile.path),
      });

      final response = await _dio.post(
        '/products/$productId/image',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['image_url'] ?? '';
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  // Get product recommendations
  Future<List<Product>> getProductRecommendations(int productId) async {
    try {
      final response = await _dio.get('/products/$productId/recommendations');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => Product.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load product recommendations');
      }
    } catch (e) {
      throw Exception('Error fetching product recommendations: $e');
    }
  }

  // Get product reviews
  Future<List<Map<String, dynamic>>> getProductReviews(int productId) async {
    try {
      final response = await _dio.get('/products/$productId/reviews');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load product reviews');
      }
    } catch (e) {
      throw Exception('Error fetching product reviews: $e');
    }
  }

  // Add product review
  Future<void> addProductReview(
      int productId, Map<String, dynamic> review) async {
    try {
      final response =
          await _dio.post('/products/$productId/reviews', data: review);

      if (response.statusCode != 201) {
        throw Exception('Failed to add review');
      }
    } catch (e) {
      throw Exception('Error adding review: $e');
    }
  }

  // Get product inventory
  Future<Map<String, dynamic>> getProductInventory(int productId) async {
    try {
      final response = await _dio.get('/products/$productId/inventory');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load product inventory');
      }
    } catch (e) {
      throw Exception('Error fetching product inventory: $e');
    }
  }

  // Update product inventory
  Future<void> updateProductInventory(
      int productId, Map<String, dynamic> inventory) async {
    try {
      final response =
          await _dio.put('/products/$productId/inventory', data: inventory);

      if (response.statusCode != 200) {
        throw Exception('Failed to update inventory');
      }
    } catch (e) {
      throw Exception('Error updating inventory: $e');
    }
  }

  // Get product categories
  Future<List<Category>> getProductCategories() async {
    try {
      final response = await _dio.get('/categories');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => Category.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  // Get products with pagination
  Future<Map<String, dynamic>> getProductsPaginated({
    int? tenantId,
    int? categoryId,
    String? search,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (tenantId != null) queryParams['tenant_id'] = tenantId;
      if (categoryId != null) queryParams['category_id'] = categoryId;
      if (search != null) queryParams['search'] = search;
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;

      final response =
          await _dio.get('/products', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'products': (data['data'] as List<dynamic>)
              .map((json) => Product.fromMap(json))
              .toList(),
          'pagination': data['pagination'] ?? {},
          'total': data['total'] ?? 0,
          'page': data['page'] ?? page,
          'limit': data['limit'] ?? limit,
        };
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  // Get product statistics
  Future<Map<String, dynamic>> getProductStatistics({int? tenantId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (tenantId != null) queryParams['tenant_id'] = tenantId;

      final response =
          await _dio.get('/products/statistics', queryParameters: queryParams);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load product statistics');
      }
    } catch (e) {
      throw Exception('Error fetching product statistics: $e');
    }
  }

  // Bulk update products
  Future<void> bulkUpdateProducts(List<Map<String, dynamic>> updates) async {
    try {
      final response =
          await _dio.put('/products/bulk', data: {'updates': updates});

      if (response.statusCode != 200) {
        throw Exception('Failed to bulk update products');
      }
    } catch (e) {
      throw Exception('Error bulk updating products: $e');
    }
  }

  // Export products
  Future<String> exportProducts({
    int? tenantId,
    String format = 'csv',
  }) async {
    try {
      final queryParams = <String, dynamic>{'format': format};
      if (tenantId != null) queryParams['tenant_id'] = tenantId;

      final response =
          await _dio.get('/products/export', queryParameters: queryParams);

      if (response.statusCode == 200) {
        return response.data['download_url'] ?? '';
      } else {
        throw Exception('Failed to export products');
      }
    } catch (e) {
      throw Exception('Error exporting products: $e');
    }
  }

  // Import products
  Future<Map<String, dynamic>> importProducts(File file,
      {int? tenantId}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        if (tenantId != null) 'tenant_id': tenantId,
      });

      final response = await _dio.post('/products/import', data: formData);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to import products');
      }
    } catch (e) {
      throw Exception('Error importing products: $e');
    }
  }
}

// Provider for ProductService
final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService(ref.watch(dioProvider));
});
