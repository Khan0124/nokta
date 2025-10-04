import 'dart:async';

import '../models/dynamic_price_adjustment.dart';
import '../models/product.dart';

class DynamicPricingService {
  DynamicPricingService({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  final List<DynamicPriceAdjustment> _seedAdjustments = [
    const DynamicPriceAdjustment(
      id: 'launch-lunch-special',
      name: 'Lunch Rush 15%',
      description: 'Automatic lunch special for featured wraps and mains.',
      type: DynamicPriceType.percentage,
      percentageValue: 15,
      productIds: [3, 4],
      channels: ['pos', 'customer'],
      priority: 50,
      stackable: false,
      startAt: null,
      endAt: null,
      status: DynamicPriceStatus.active,
    ),
    const DynamicPriceAdjustment(
      id: 'evening-family-bundle',
      name: 'Family Bundle SAR 99',
      description: 'Set price for popular family combinations after 5pm.',
      type: DynamicPriceType.fixed,
      fixedPrice: 99,
      productIds: [2, 3, 5],
      channels: ['customer'],
      priority: 40,
      stackable: false,
      startAt: null,
      endAt: null,
      status: DynamicPriceStatus.scheduled,
    ),
  ];

  Future<List<DynamicPriceAdjustment>> fetchAdjustments({
    String channel = 'pos',
    int? branchId,
    bool includeUnavailable = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final now = _clock();
    return _seedAdjustments
        .where((adjustment) => includeUnavailable || !adjustment.isAvailabilityOverride)
        .where((adjustment) => adjustment.appliesToChannel(channel))
        .where((adjustment) => adjustment.appliesToBranch(branchId))
        .where((adjustment) => adjustment.isWithinWindow(now))
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }

  double resolvePrice(
    Product product, {
    String channel = 'pos',
    int? branchId,
    List<DynamicPriceAdjustment>? adjustments,
  }) {
    final now = _clock();
    final source = adjustments ?? _seedAdjustments;

    final eligible = source
        .where((adjustment) => adjustment.appliesToProduct(product.id))
        .where((adjustment) => adjustment.appliesToChannel(channel))
        .where((adjustment) => adjustment.appliesToBranch(branchId))
        .where((adjustment) => adjustment.isWithinWindow(now))
        .where((adjustment) => adjustment.status == DynamicPriceStatus.active)
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    if (eligible.isEmpty) {
      return product.price;
    }

    var price = product.price;
    for (final adjustment in eligible) {
      price = adjustment.evaluate(price);
      if (!adjustment.stackable) {
        break;
      }
    }

    return double.parse(price.toStringAsFixed(2));
  }

  List<DynamicPriceAdjustment> get seedAdjustments => List.unmodifiable(_seedAdjustments);
}
