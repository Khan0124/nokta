import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokta_core/models/cart_item.dart';
import 'package:nokta_core/models/order.dart';
import 'package:nokta_core/models/product.dart';
import 'package:nokta_core/models/products_query.dart';
import 'package:nokta_core/providers/cart_provider.dart';
import 'package:nokta_core/providers/category_provider.dart';
import 'package:nokta_core/providers/product_provider.dart';

class EnhancedPOSScreen extends ConsumerStatefulWidget {
  const EnhancedPOSScreen({super.key});

  @override
  ConsumerState<EnhancedPOSScreen> createState() => _EnhancedPOSScreenState();
}

class _EnhancedPOSScreenState extends ConsumerState<EnhancedPOSScreen> {
  int _selectedCategoryId = 0;
  OrderType _orderType = OrderType.dineIn;

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('نقطة البيع'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.refresh(productsProvider(const ProductsQuery())),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Panel - Categories & Products
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Category Tabs
                _buildCategoryTabs(),

                // Product Grid
                Expanded(
                  child: _buildProductGrid(),
                ),
              ],
            ),
          ),

          // Right Panel - Cart & Actions
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  left: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Column(
                children: [
                  // Order Type Selection
                  _buildOrderTypeSelector(),

                  // Cart Items
                  Expanded(
                    child: _buildCartItems(cart.items),
                  ),

                  // Cart Summary
                  _buildCartSummary(cart),

                  // Action Buttons
                  _buildActionButtons(cart.items),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: categoriesAsync.when(
        data: (categories) => ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: const Text('الكل'),
                  selected: _selectedCategoryId == 0,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategoryId = 0);
                  },
                ),
              );
            }

            final category = categories[index - 1];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(category.name),
                selected: _selectedCategoryId == category.id,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedCategoryId = category.id);
                  }
                },
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('خطأ: $error')),
      ),
    );
  }

  Widget _buildProductGrid() {
    final query = ProductsQuery(
      categoryId: _selectedCategoryId == 0 ? null : _selectedCategoryId,
      isAvailable: true,
    );
    final productsAsync = ref.watch(productsProvider(query));

    return productsAsync.when(
      data: (products) => GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductCard(product);
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('خطأ: $error')),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      child: InkWell(
        onTap: () => _addToCart(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: product.image != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8)),
                        child: Image.network(
                          product.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.restaurant, size: 40),
                        ),
                      )
                    : const Icon(Icons.restaurant, size: 40),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      '${product.price.toStringAsFixed(2)} ر.س',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'نوع الطلب',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<OrderType>(
            segments: const [
              ButtonSegment(
                value: OrderType.dineIn,
                label: Text('محلي'),
                icon: Icon(Icons.restaurant),
              ),
              ButtonSegment(
                value: OrderType.takeaway,
                label: Text('خارجي'),
                icon: Icon(Icons.shopping_bag),
              ),
              ButtonSegment(
                value: OrderType.delivery,
                label: Text('توصيل'),
                icon: Icon(Icons.delivery_dining),
              ),
            ],
            selected: {_orderType},
            onSelectionChanged: (types) {
              setState(() => _orderType = types.first);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(List<CartItem> cartItems) {
    if (cartItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'السلة فارغة',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'اضغط على منتج لإضافته',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        final item = cartItems[index];
        return _buildCartItem(item);
      },
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeFromCart(item.product),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    ref.read(cartProvider.notifier).updateItemQuantity(
                          item.id,
                          item.quantity - 1,
                        );
                  },
                ),
                Text('${item.quantity}', style: const TextStyle(fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    ref.read(cartProvider.notifier).updateItemQuantity(
                          item.id,
                          item.quantity + 1,
                        );
                  },
                ),
                const Spacer(),
                Text(
                  '${item.totalPrice.toStringAsFixed(2)} ر.س',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(CartState cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('المجموع الجزئي:'),
              Text('${cart.subtotal.toStringAsFixed(2)} ر.س'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الضريبة:'),
              Text('${cart.tax.toStringAsFixed(2)} ر.س'),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الإجمالي:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${cart.total.toStringAsFixed(2)} ر.س',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(List<CartItem> cartItems) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _clearCart(),
                  icon: const Icon(Icons.clear),
                  label: const Text('مسح السلة'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: cartItems.isEmpty ? null : () => _holdOrder(),
                  icon: const Icon(Icons.pause),
                  label: const Text('حفظ'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: cartItems.isEmpty ? null : () => _processPayment(),
              icon: const Icon(Icons.payment),
              label: const Text('دفع'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(Product product) {
    ref.read(cartProvider.notifier).addItem(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إضافة ${product.name} إلى السلة'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _removeFromCart(Product product) {
    ref.read(cartProvider.notifier).removeItem(product.id);
  }

  void _updateQuantity(Product product, int quantity) {
    if (quantity <= 0) {
      _removeFromCart(product);
    } else {
      // Find the cart item for this product and update its quantity
      final cartItem = ref.read(cartProvider).items.firstWhere(
            (item) => item.product.id == product.id,
            orElse: () => throw Exception('Product not found in cart'),
          );
      ref.read(cartProvider.notifier).updateItemQuantity(cartItem.id, quantity);
    }
  }

  void _clearCart() {
    ref.read(cartProvider.notifier).clearCart();
  }

  void _holdOrder() {
    // TODO: Implement hold order functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ الطلب')),
    );
  }

  void _processPayment() {
    // TODO: Implement payment processing
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('معالجة الدفع'),
        content: const Text('سيتم تنفيذ معالجة الدفع قريباً'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
}
