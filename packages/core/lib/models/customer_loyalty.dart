import 'package:collection/collection.dart';

class LoyaltyReward {
  const LoyaltyReward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsRequired,
    this.expiresAt,
    this.redeemedAt,
    this.code,
  });

  final String id;
  final String title;
  final String description;
  final int pointsRequired;
  final DateTime? expiresAt;
  final DateTime? redeemedAt;
  final String? code;

  bool get isRedeemed => redeemedAt != null;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  LoyaltyReward copyWith({
    String? id,
    String? title,
    String? description,
    int? pointsRequired,
    DateTime? expiresAt,
    DateTime? redeemedAt,
    String? code,
  }) {
    return LoyaltyReward(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      pointsRequired: pointsRequired ?? this.pointsRequired,
      expiresAt: expiresAt ?? this.expiresAt,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      code: code ?? this.code,
    );
  }
}

class LoyaltySummary {
  const LoyaltySummary({
    required this.customerId,
    required this.pointsBalance,
    required this.tier,
    required this.nextTierThreshold,
    required this.rewards,
    required this.ordersThisMonth,
    required this.freeDeliveryVouchers,
    required this.lastUpdated,
  });

  final int customerId;
  final int pointsBalance;
  final String tier;
  final int nextTierThreshold;
  final List<LoyaltyReward> rewards;
  final int ordersThisMonth;
  final int freeDeliveryVouchers;
  final DateTime lastUpdated;

  int get pointsToNextTier =>
      (nextTierThreshold - pointsBalance).clamp(0, nextTierThreshold);

  double get progressToNextTier =>
      nextTierThreshold == 0 ? 1 : (pointsBalance / nextTierThreshold).clamp(0, 1);

  LoyaltyReward? get nextReward =>
      rewards.firstWhereOrNull((reward) => !reward.isRedeemed && !reward.isExpired);

  bool get hasActiveRewards =>
      rewards.any((reward) => !reward.isRedeemed && !reward.isExpired);

  LoyaltySummary copyWith({
    int? customerId,
    int? pointsBalance,
    String? tier,
    int? nextTierThreshold,
    List<LoyaltyReward>? rewards,
    int? ordersThisMonth,
    int? freeDeliveryVouchers,
    DateTime? lastUpdated,
  }) {
    return LoyaltySummary(
      customerId: customerId ?? this.customerId,
      pointsBalance: pointsBalance ?? this.pointsBalance,
      tier: tier ?? this.tier,
      nextTierThreshold: nextTierThreshold ?? this.nextTierThreshold,
      rewards: rewards ?? this.rewards,
      ordersThisMonth: ordersThisMonth ?? this.ordersThisMonth,
      freeDeliveryVouchers:
          freeDeliveryVouchers ?? this.freeDeliveryVouchers,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

enum LoyaltyTier { bronze, silver, gold, platinum, diamond }

LoyaltyTier loyaltyTierFromString(String? value, {int points = 0}) {
  if (value == null || value.isEmpty) {
    return loyaltyTierFromPoints(points);
  }
  final normalized = value.toLowerCase();
  return LoyaltyTier.values.firstWhere(
    (tier) => tier.name == normalized,
    orElse: () => loyaltyTierFromPoints(points),
  );
}

LoyaltyTier loyaltyTierFromPoints(int points) {
  if (points >= 5000) return LoyaltyTier.diamond;
  if (points >= 2500) return LoyaltyTier.platinum;
  if (points >= 1000) return LoyaltyTier.gold;
  if (points >= 500) return LoyaltyTier.silver;
  return LoyaltyTier.bronze;
}

class CustomerRecentOrder {
  const CustomerRecentOrder({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  factory CustomerRecentOrder.fromJson(Map<String, dynamic> json) {
    return CustomerRecentOrder(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      orderNumber: json['orderNumber']?.toString() ?? '-',
      totalAmount: json['totalAmount'] is num ? (json['totalAmount'] as num).toDouble() : 0,
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  final int id;
  final String orderNumber;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
}

class CustomerLoyaltyProfile {
  const CustomerLoyaltyProfile({
    required this.customerId,
    required this.fullName,
    required this.phone,
    required this.tier,
    required this.totalPoints,
    required this.availablePoints,
    required this.lifetimeValue,
    required this.favoriteBranches,
    required this.optedInChannels,
    required this.lastUpdated,
    this.email,
    this.preferredBranchId,
    this.recentOrders = const [],
  });

  factory CustomerLoyaltyProfile.fromJson(Map<String, dynamic> json) {
    final points = json['loyaltyPoints'] is num ? (json['loyaltyPoints'] as num).round() : 0;
    final recentOrders = (json['recentOrders'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CustomerRecentOrder.fromJson)
        .toList(growable: false);

    final favoriteBranches = <String>[];
    if (json['favoriteBranches'] is List) {
      favoriteBranches.addAll(
        (json['favoriteBranches'] as List)
            .map((branch) => branch.toString())
            .where((branch) => branch.isNotEmpty),
      );
    } else if (json['preferredBranchId'] != null) {
      favoriteBranches.add(json['preferredBranchId'].toString());
    }

    final optedInChannels = (json['optedInChannels'] as List<dynamic>? ?? [])
        .map((channel) => channel.toString())
        .where((channel) => channel.isNotEmpty)
        .toList(growable: false);

    return CustomerLoyaltyProfile(
      customerId: json['customerId'] is num
          ? (json['customerId'] as num).toInt()
          : (json['id'] as num?)?.toInt() ?? 0,
      fullName: json['fullName']?.toString() ?? json['name']?.toString() ?? 'Unknown Customer',
      phone: json['phone']?.toString() ?? json['callerNumber']?.toString() ?? '-',
      tier: loyaltyTierFromString(json['tier']?.toString(), points: points),
      totalPoints: points,
      availablePoints: json['availablePoints'] is num
          ? (json['availablePoints'] as num).round()
          : points,
      lifetimeValue: json['lifetimeValue'] is num
          ? (json['lifetimeValue'] as num).toDouble()
          : (json['totalSpent'] as num?)?.toDouble() ?? 0,
      favoriteBranches: favoriteBranches,
      optedInChannels: optedInChannels,
      lastUpdated: DateTime.tryParse(json['lastUpdated']?.toString() ?? '') ?? DateTime.now(),
      email: json['email']?.toString(),
      preferredBranchId: json['preferredBranchId'] as int?,
      recentOrders: recentOrders,
    );
  }

  final int customerId;
  final String fullName;
  final String phone;
  final LoyaltyTier tier;
  final int totalPoints;
  final int availablePoints;
  final double lifetimeValue;
  final List<String> favoriteBranches;
  final List<String> optedInChannels;
  final DateTime lastUpdated;
  final String? email;
  final int? preferredBranchId;
  final List<CustomerRecentOrder> recentOrders;

  CustomerLoyaltyProfile copyWith({
    LoyaltyTier? tier,
    int? totalPoints,
    int? availablePoints,
    double? lifetimeValue,
    List<String>? favoriteBranches,
    List<String>? optedInChannels,
    DateTime? lastUpdated,
    List<CustomerRecentOrder>? recentOrders,
  }) {
    return CustomerLoyaltyProfile(
      customerId: customerId,
      fullName: fullName,
      phone: phone,
      tier: tier ?? this.tier,
      totalPoints: totalPoints ?? this.totalPoints,
      availablePoints: availablePoints ?? this.availablePoints,
      lifetimeValue: lifetimeValue ?? this.lifetimeValue,
      favoriteBranches: favoriteBranches ?? this.favoriteBranches,
      optedInChannels: optedInChannels ?? this.optedInChannels,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      email: email,
      preferredBranchId: preferredBranchId,
      recentOrders: recentOrders ?? this.recentOrders,
    );
  }
}
