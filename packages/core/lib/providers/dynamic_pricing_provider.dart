import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dynamic_price_adjustment.dart';
import '../models/product.dart';
import '../services/dynamic_pricing_service.dart';

final dynamicPricingServiceProvider = Provider<DynamicPricingService>((ref) {
  final service = DynamicPricingService();
  return service;
});

final dynamicPricingAdjustmentsProvider = FutureProvider.autoDispose<List<DynamicPriceAdjustment>>((ref) async {
  final service = ref.watch(dynamicPricingServiceProvider);
  return service.fetchAdjustments();
});

final productDynamicPriceProvider = Provider.family<double, Product>((ref, product) {
  final asyncAdjustments = ref.watch(dynamicPricingAdjustmentsProvider);
  return asyncAdjustments.maybeWhen(
    data: (adjustments) {
      final service = ref.read(dynamicPricingServiceProvider);
      return service.resolvePrice(
        product,
        adjustments: adjustments,
      );
    },
    orElse: () => product.price,
  );
});
