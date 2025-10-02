// import 'package:freezed_annotation/freezed_annotation.dart';

// part 'product_analytics.freezed.dart';
// part 'product_analytics.g.dart';

// @freezed
class ProductAnalytics {
  // const factory ProductAnalytics({
  const ProductAnalytics({
    required this.productId,
    required this.totalOrders,
    required this.totalRevenue,
    required this.averageRating,
    required this.reviewCount,
    this.dailyOrders,
    this.weeklyOrders,
    this.monthlyOrders,
    this.topModifiers,
    this.customerSegments,
    this.peakHours,
    this.seasonalTrends,
    this.createdAt,
    this.updatedAt,
  });

  final int productId;
  final int totalOrders;
  final double totalRevenue;
  final double averageRating;
  final int reviewCount;
  final Map<String, int>? dailyOrders;
  final Map<String, int>? weeklyOrders;
  final Map<String, int>? monthlyOrders;
  final List<ModifierAnalytics>? topModifiers;
  final List<CustomerSegment>? customerSegments;
  final List<PeakHour>? peakHours;
  final List<SeasonalTrend>? seasonalTrends;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // factory ProductAnalytics.fromJson(Map<String, dynamic> json) => _$ProductAnalyticsFromJson(json);

  factory ProductAnalytics.fromMap(Map<String, dynamic> map) {
    return ProductAnalytics(
      productId: map['product_id'] as int,
      totalOrders: map['total_orders'] as int,
      totalRevenue: (map['total_revenue'] as num).toDouble(),
      averageRating: (map['average_rating'] as num).toDouble(),
      reviewCount: map['review_count'] as int,
      dailyOrders: map['daily_orders'] != null
          ? Map<String, int>.from(map['daily_orders'] as Map)
          : null,
      weeklyOrders: map['weekly_orders'] != null
          ? Map<String, int>.from(map['weekly_orders'] as Map)
          : null,
      monthlyOrders: map['monthly_orders'] != null
          ? Map<String, int>.from(map['monthly_orders'] as Map)
          : null,
      topModifiers: map['top_modifiers'] != null
          ? (map['top_modifiers'] as List<dynamic>)
              .map((modifier) => ModifierAnalytics.fromMap(modifier as Map<String, dynamic>))
              .toList()
          : null,
      customerSegments: map['customer_segments'] != null
          ? (map['customer_segments'] as List<dynamic>)
              .map((segment) => CustomerSegment.fromMap(segment as Map<String, dynamic>))
              .toList()
          : null,
      peakHours: map['peak_hours'] != null
          ? (map['peak_hours'] as List<dynamic>)
              .map((hour) => PeakHour.fromMap(hour as Map<String, dynamic>))
              .toList()
          : null,
      seasonalTrends: map['seasonal_trends'] != null
          ? (map['seasonal_trends'] as List<dynamic>)
              .map((trend) => SeasonalTrend.fromMap(trend as Map<String, dynamic>))
              .toList()
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'total_orders': totalOrders,
      'total_revenue': totalRevenue,
      'average_rating': averageRating,
      'review_count': reviewCount,
      'daily_orders': dailyOrders,
      'weekly_orders': weeklyOrders,
      'monthly_orders': monthlyOrders,
      'top_modifiers': topModifiers?.map((modifier) => modifier.toMap()).toList(),
      'customer_segments': customerSegments?.map((segment) => segment.toMap()).toList(),
      'peak_hours': peakHours?.map((hour) => hour.toMap()).toList(),
      'seasonal_trends': seasonalTrends?.map((trend) => trend.toMap()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  ProductAnalytics copyWith({
    int? productId,
    int? totalOrders,
    double? totalRevenue,
    double? averageRating,
    int? reviewCount,
    Map<String, int>? dailyOrders,
    Map<String, int>? weeklyOrders,
    Map<String, int>? monthlyOrders,
    List<ModifierAnalytics>? topModifiers,
    List<CustomerSegment>? customerSegments,
    List<PeakHour>? peakHours,
    List<SeasonalTrend>? seasonalTrends,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductAnalytics(
      productId: productId ?? this.productId,
      totalOrders: totalOrders ?? this.totalOrders,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      dailyOrders: dailyOrders ?? this.dailyOrders,
      weeklyOrders: weeklyOrders ?? this.weeklyOrders,
      monthlyOrders: monthlyOrders ?? this.monthlyOrders,
      topModifiers: topModifiers ?? this.topModifiers,
      customerSegments: customerSegments ?? this.customerSegments,
      peakHours: peakHours ?? this.peakHours,
      seasonalTrends: seasonalTrends ?? this.seasonalTrends,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// @freezed
class ModifierAnalytics {
  // const factory ModifierAnalytics({
  const ModifierAnalytics({
    required this.modifierId,
    required this.name,
    required this.usageCount,
    required this.revenue,
  });

  final int modifierId;
  final String name;
  final int usageCount;
  final double revenue;

  // factory ModifierAnalytics.fromJson(Map<String, dynamic> json) => _$ModifierAnalyticsFromJson(json);

  factory ModifierAnalytics.fromMap(Map<String, dynamic> map) {
    return ModifierAnalytics(
      modifierId: map['modifier_id'] as int,
      name: map['name'] as String,
      usageCount: map['usage_count'] as int,
      revenue: (map['revenue'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'modifier_id': modifierId,
      'name': name,
      'usage_count': usageCount,
      'revenue': revenue,
    };
  }

  Map<String, dynamic> toJson() => toMap();
}

// @freezed
class CustomerSegment {
  // const factory CustomerSegment({
  const CustomerSegment({
    required this.segmentName,
    required this.customerCount,
    required this.averageOrderValue,
  });

  final String segmentName;
  final int customerCount;
  final double averageOrderValue;

  // factory CustomerSegment.fromJson(Map<String, dynamic> json) => _$CustomerSegmentFromJson(json);

  factory CustomerSegment.fromMap(Map<String, dynamic> map) {
    return CustomerSegment(
      segmentName: map['segment_name'] as String,
      customerCount: map['customer_count'] as int,
      averageOrderValue: (map['average_order_value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'segment_name': segmentName,
      'customer_count': customerCount,
      'average_order_value': averageOrderValue,
    };
  }

  Map<String, dynamic> toJson() => toMap();
}

// @freezed
class PeakHour {
  // const factory PeakHour({
  const PeakHour({
    required this.hour,
    required this.orderCount,
  });

  final int hour;
  final int orderCount;

  // factory PeakHour.fromJson(Map<String, dynamic> json) => _$PeakHourFromJson(json);

  factory PeakHour.fromMap(Map<String, dynamic> map) {
    return PeakHour(
      hour: map['hour'] as int,
      orderCount: map['order_count'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hour': hour,
      'order_count': orderCount,
    };
  }

  Map<String, dynamic> toJson() => toMap();
}

// @freezed
class SeasonalTrend {
  // const factory SeasonalTrend({
  const SeasonalTrend({
    required this.month,
    required this.orderCount,
    required this.revenue,
  });

  final String month;
  final int orderCount;
  final double revenue;

  // factory SeasonalTrend.fromJson(Map<String, dynamic> json) => _$SeasonalTrendFromJson(json);

  factory SeasonalTrend.fromMap(Map<String, dynamic> map) {
    return SeasonalTrend(
      month: map['month'] as String,
      orderCount: map['order_count'] as int,
      revenue: (map['revenue'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'order_count': orderCount,
      'revenue': revenue,
    };
  }

  Map<String, dynamic> toJson() => toMap();
}
