class CustomerAddress {
  final String id;
  final String title;
  final String address;
  final double latitude;
  final double longitude;
  final String? notes;
  final bool isDefault;

  const CustomerAddress({
    required this.id,
    required this.title,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.notes,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
      'isDefault': isDefault,
    };
  }

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: json['id'] as String,
      title: json['title'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      notes: json['notes'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}
