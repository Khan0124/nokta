import 'package:nokta_core/models/category.dart';
import 'package:nokta_core/models/product.dart';

class RestaurantSummary {
  const RestaurantSummary({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.ratingCount,
    required this.estimatedDeliveryMinutes,
    required this.deliveryFee,
    required this.isFavorite,
    required this.isOpen,
    required this.distanceKm,
    required this.heroImage,
    required this.tags,
  });

  final int id;
  final String name;
  final String cuisine;
  final double rating;
  final int ratingCount;
  final RangeValues estimatedDeliveryMinutes;
  final double deliveryFee;
  final bool isFavorite;
  final bool isOpen;
  final double distanceKm;
  final String heroImage;
  final List<String> tags;
}

class RangeValues {
  const RangeValues(this.min, this.max);

  final int min;
  final int max;

  @override
  String toString() => '$min-$max';
}

class MenuSection {
  const MenuSection({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.items,
  });

  final String id;
  final String name;
  final String description;
  final Category category;
  final List<Product> items;
}

class RestaurantDetail {
  const RestaurantDetail({
    required this.summary,
    required this.about,
    required this.sections,
    required this.address,
    required this.phone,
    required this.openingHours,
    required this.supportsPickup,
    required this.supportsDelivery,
    required this.averageSpend,
    required this.paymentMethods,
    required this.chefNotes,
  });

  final RestaurantSummary summary;
  final String about;
  final List<MenuSection> sections;
  final String address;
  final String phone;
  final String openingHours;
  final bool supportsPickup;
  final bool supportsDelivery;
  final double averageSpend;
  final List<String> paymentMethods;
  final List<String> chefNotes;

  List<Product> get allProducts =>
      sections.expand((section) => section.items).toList();
}
