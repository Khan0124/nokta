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
