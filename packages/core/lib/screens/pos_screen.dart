import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../db/local_db.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({Key? key}) : super(key: key);
  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  List<Product> _catalog = [];
  final List<CartItem> _cart = [];

  String _orderType = 'محلي';
  String _paymentMethod = 'نقدًا';

  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _customerAddressCtrl = TextEditingController();

  bool _isLoadingProducts = true;
  bool _isSubmittingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _customerAddressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ProductService.fetchProducts();
      setState(() {
        _catalog = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل المنتجات: $e')),
      );
    }
  }

  void _addToCart(Product product) {
    final index = _cart.indexWhere((item) => item.product.id == product.id);
    setState(() {
      if (index == -1) {
        _cart.add(CartItem(
          id: DateTime.now().millisecondsSinceEpoch,
          product: product,
          quantity: 1,
          unitPrice: product.price,
          totalPrice: product.price,
        ));
      } else {
        final currentItem = _cart[index];
        _cart[index] = currentItem.copyWith(
          quantity: currentItem.quantity + 1,
          totalPrice: product.price * (currentItem.quantity + 1),
        );
      }
    });
  }

  void _removeFromCart(CartItem item) {
    setState(() {
      _cart.remove(item);
    });
  }

  double get _total =>
      _cart.fold(0, (sum, item) => sum + item.product.price * item.quantity);

  Future<void> _submitOrder() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('السلة فارغة! أضف منتجات أولاً')),
      );
      return;
    }

    if (_orderType == 'توصيل') {
      if (_customerNameCtrl.text.trim().isEmpty ||
          _customerPhoneCtrl.text.trim().isEmpty ||
          _customerAddressCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى إدخال بيانات العميل للتوصيل')),
        );
        return;
      }
    }

    setState(() {
      _isSubmittingOrder = true;
    });

    try {
      if (!kIsWeb) {
        final db = LocalDB.instance;
        final order = Order(
          id: 0,
          tenantId: 1,
          branchId: 1,
          customerId: 1, // Default customer ID
          orderType: OrderType.dineIn,
          status: OrderStatus.pending,
          items: _cart.map((item) => OrderItem.fromCartItem(item)).toList(),
          subtotal: _total,
          tax: _total * 0.15,
          deliveryFee: 0,
          total: _total + (_total * 0.15),
          paymentMethod: _paymentMethod,
          paymentStatus: PaymentStatus.pending,
          deliveryAddress: _customerAddressCtrl.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await db.insertOrder(order);
        setState(() {
          _cart.clear();
          _customerNameCtrl.clear();
          _customerPhoneCtrl.clear();
          _customerAddressCtrl.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الطلب بنجاح')),
        );
      } else {
        // مستقبلًا: إضافة دعم API للويب
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم حفظ الطلب (نسخة الويب - عرض فقط حالياً)')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في حفظ الطلب: $e')),
      );
    } finally {
      setState(() {
        _isSubmittingOrder = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نقطة البيع')),
      body: Row(
        children: [
          // جزء الفاتورة
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('الفاتورة', style: TextStyle(fontSize: 20)),
                  const Divider(),
                  if (_cart.isEmpty) const Center(child: Text('السلة فارغة')),
                  ..._cart.map(
                    (item) => ListTile(
                      title: Text('${item.product.name} × ${item.quantity}'),
                      trailing: Text(
                          '${(item.product.price * item.quantity).toStringAsFixed(2)} SDG'),
                      onTap: () => _removeFromCart(item),
                    ),
                  ),
                  const Divider(),
                  Text(
                    'الإجمالي: ${_total.toStringAsFixed(2)} SDG',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _orderType,
                    items: ['محلي', 'سفري', 'توصيل']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _orderType = val!;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'نوع الطلب'),
                  ),
                  if (_orderType == 'توصيل') ...[
                    TextField(
                      controller: _customerNameCtrl,
                      decoration:
                          const InputDecoration(labelText: 'اسم العميل'),
                    ),
                    TextField(
                      controller: _customerPhoneCtrl,
                      decoration:
                          const InputDecoration(labelText: 'رقم الهاتف'),
                      keyboardType: TextInputType.phone,
                    ),
                    TextField(
                      controller: _customerAddressCtrl,
                      decoration: const InputDecoration(labelText: 'العنوان'),
                    ),
                  ],
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    items: ['نقدًا', 'بطاقة', 'تحويل بنكي']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _paymentMethod = val!;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'طريقة الدفع'),
                  ),
                  const SizedBox(height: 12),
                  _isSubmittingOrder
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _submitOrder,
                          child: const Text('دفع و حفظ الطلب'),
                        ),
                ],
              ),
            ),
          ),
          // جزء الكتالوج
          Expanded(
            flex: 3,
            child: _isLoadingProducts
                ? const Center(child: CircularProgressIndicator())
                : _catalog.isEmpty
                    ? const Center(child: Text('لا توجد أصناف'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: .9,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _catalog.length,
                        itemBuilder: (_, i) {
                          final p = _catalog[i];
                          return InkWell(
                            onTap: () => _addToCart(p),
                            child: Card(
                              elevation: 2,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(p.name, textAlign: TextAlign.center),
                                    const SizedBox(height: 6),
                                    Text('${p.price.toStringAsFixed(2)} SDG'),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
