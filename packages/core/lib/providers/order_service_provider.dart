import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/order_service.dart';
import 'dio_provider.dart';

final orderServiceProvider = Provider<OrderService>((ref) {
  final dio = ref.watch(dioProvider);
  return OrderService(dio);
});
