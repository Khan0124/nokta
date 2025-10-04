import 'package:equatable/equatable.dart';

class DynamicPriceAdjustment extends Equatable {
  const DynamicPriceAdjustment({
    required this.id,
    required this.name,
    this.description = '',
    required this.type,
    this.percentageValue,
    this.fixedPrice,
    required this.productIds,
    this.branchIds = const <int>[],
    this.channels = const <String>['pos'],
    this.priority = 100,
    this.stackable = false,
    this.startAt,
    this.endAt,
    this.status = DynamicPriceStatus.scheduled,
  });

  final String id;
  final String name;
  final String description;
  final DynamicPriceType type;
  final double? percentageValue;
  final double? fixedPrice;
  final List<int> productIds;
  final List<int> branchIds;
  final List<String> channels;
  final int priority;
  final bool stackable;
  final DateTime? startAt;
  final DateTime? endAt;
  final DynamicPriceStatus status;

  bool appliesToProduct(int productId) {
    if (productIds.isEmpty) {
      return true;
    }
    return productIds.contains(productId);
  }

  bool appliesToBranch(int? branchId) {
    if (branchId == null || branchIds.isEmpty) {
      return true;
    }
    return branchIds.contains(branchId);
  }

  bool appliesToChannel(String channel) {
    if (channels.isEmpty) {
      return true;
    }
    return channels.contains(channel);
  }

  bool isWithinWindow(DateTime reference) {
    if (startAt != null && startAt!.isAfter(reference)) {
      return false;
    }
    if (endAt != null && endAt!.isBefore(reference)) {
      return false;
    }
    return true;
  }

  bool get isAvailabilityOverride => type == DynamicPriceType.availability;

  double evaluate(double basePrice) {
    switch (type) {
      case DynamicPriceType.percentage:
        final modifier = (percentageValue ?? 0) / 100;
        final adjusted = basePrice - (basePrice * modifier);
        return adjusted.clamp(0, double.infinity);
      case DynamicPriceType.fixed:
        return (fixedPrice ?? basePrice).clamp(0, double.infinity);
      case DynamicPriceType.availability:
        return basePrice;
    }
  }

  DynamicPriceAdjustment copyWith({
    DynamicPriceStatus? status,
  }) {
    return DynamicPriceAdjustment(
      id: id,
      name: name,
      description: description,
      type: type,
      percentageValue: percentageValue,
      fixedPrice: fixedPrice,
      productIds: productIds,
      branchIds: branchIds,
      channels: channels,
      priority: priority,
      stackable: stackable,
      startAt: startAt,
      endAt: endAt,
      status: status ?? this.status,
    );
  }

  factory DynamicPriceAdjustment.fromJson(Map<String, dynamic> json) {
    return DynamicPriceAdjustment(
      id: json['id'] as String,
      name: json['name'] as String,
      description: (json['description'] ?? '') as String,
      type: DynamicPriceTypeX.parse(json['type'] as String?),
      percentageValue: (json['value'] as num?)?.toDouble(),
      fixedPrice: (json['fixedPrice'] as num?)?.toDouble(),
      productIds: ((json['productIds'] as List<dynamic>?) ?? const <dynamic>[])
          .map((value) => (value as num).toInt())
          .toList(),
      branchIds: ((json['branchIds'] as List<dynamic>?) ?? const <dynamic>[])
          .map((value) => (value as num).toInt())
          .toList(),
      channels: ((json['channels'] as List<dynamic>?) ?? const <dynamic>[])
          .map((value) => value.toString())
          .toList(),
      priority: (json['priority'] as num?)?.toInt() ?? 100,
      stackable: json['stackable'] as bool? ?? false,
      startAt: json['startAt'] != null
          ? DateTime.tryParse(json['startAt'] as String)
          : null,
      endAt:
          json['endAt'] != null ? DateTime.tryParse(json['endAt'] as String) : null,
      status: DynamicPriceStatusX.parse(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'value': percentageValue,
      'fixedPrice': fixedPrice,
      'productIds': productIds,
      'branchIds': branchIds,
      'channels': channels,
      'priority': priority,
      'stackable': stackable,
      'startAt': startAt?.toIso8601String(),
      'endAt': endAt?.toIso8601String(),
      'status': status.name,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        type,
        percentageValue,
        fixedPrice,
        productIds,
        branchIds,
        channels,
        priority,
        stackable,
        startAt,
        endAt,
        status,
      ];
}

enum DynamicPriceType { percentage, fixed, availability }

enum DynamicPriceStatus { scheduled, active, disabled, archived, expired }

extension DynamicPriceTypeX on DynamicPriceType {
  static DynamicPriceType parse(String? value) {
    switch (value) {
      case 'fixed':
        return DynamicPriceType.fixed;
      case 'availability':
        return DynamicPriceType.availability;
      case 'percentage':
      default:
        return DynamicPriceType.percentage;
    }
  }
}

extension DynamicPriceStatusX on DynamicPriceStatus {
  static DynamicPriceStatus parse(String? value) {
    switch (value) {
      case 'active':
        return DynamicPriceStatus.active;
      case 'disabled':
        return DynamicPriceStatus.disabled;
      case 'archived':
        return DynamicPriceStatus.archived;
      case 'expired':
        return DynamicPriceStatus.expired;
      case 'scheduled':
      default:
        return DynamicPriceStatus.scheduled;
    }
  }
}
