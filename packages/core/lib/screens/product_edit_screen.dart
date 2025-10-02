import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductEditScreen extends StatefulWidget {
  const ProductEditScreen({Key? key}) : super(key: key);

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final priceController = TextEditingController();

  bool _isSaving = false;

  Future<void> _saveProduct() async {
    final name = nameController.text.trim();
    final description = descController.text.trim();
    final price = double.tryParse(priceController.text.trim()) ?? 0.0;

    if (name.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم صالح وسعر أكبر من صفر')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final product = Product(
      id: 0, // id 0 يعني جديد
      tenantId: 1, // Default tenant
      categoryId: 1, // Default category
      name: name,
      description: description,
      price: price,
      status: ProductStatus.active,
      type: ProductType.food,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ProductService.addProduct(product);

    setState(() {
      _isSaving = false;
    });

    if (success) {
      Navigator.pop(context, true); // ترجع نجاح للحذف لو حبيت تستخدمها
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل في إضافة المنتج')),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة منتج')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'الاسم'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'الوصف'),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'السعر'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            _isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _saveProduct,
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
