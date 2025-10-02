import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../db/local_db.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  Future<List<Map<String, Object?>>> _load() async {
    if (!kIsWeb) {
      final db = LocalDB.instance;
      final orders = await db.getOrders();
      return orders.map((order) => order.toJson()).toList();
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, Object?>>>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('لا توجد طلبات.'));
        }

        final orders = snapshot.data!;

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return ListTile(
              title: Text('طلب رقم ${order['id']}'),
              subtitle: Text('الإجمالي: ${order['total']}'),
            );
          },
        );
      },
    );
  }
}
