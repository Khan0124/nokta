// import 'package:freezed_annotation/freezed_annotation.dart';

// part 'user.freezed.dart';
// part 'user.g.dart';

enum UserRole {
  superAdmin,
  admin,
  manager,
  staff,
  customer,
  driver,
}

enum UserStatus {
  active,
  inactive,
  suspended,
  pending,
}

// @freezed
class User {
  // const factory User({
  const User({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.status,
    this.phone,
    this.avatar,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.preferences,
    this.lastLoginAt,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int tenantId;
  final int branchId;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final UserStatus status;
  final String? phone;
  final String? avatar;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final Map<String, dynamic>? preferences;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      tenantId: map['tenant_id'] as int,
      branchId: map['branch_id'] as int,
      email: map['email'] as String,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.staff,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => UserStatus.active,
      ),
      phone: map['phone'] as String?,
      avatar: map['avatar'] as String?,
      dateOfBirth: map['date_of_birth'] != null
          ? DateTime.parse(map['date_of_birth'] as String)
          : null,
      gender: map['gender'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      country: map['country'] as String?,
      postalCode: map['postal_code'] as String?,
      preferences: map['preferences'] as Map<String, dynamic>?,
      lastLoginAt: map['last_login_at'] != null
          ? DateTime.parse(map['last_login_at'] as String)
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
      'id': id,
      'tenant_id': tenantId,
      'branch_id': branchId,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role.name,
      'status': status.name,
      'phone': phone,
      'avatar': avatar,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'postal_code': postalCode,
      'preferences': preferences,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  User copyWith({
    int? id,
    int? tenantId,
    int? branchId,
    String? email,
    String? firstName,
    String? lastName,
    UserRole? role,
    UserStatus? status,
    String? phone,
    String? avatar,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    Map<String, dynamic>? preferences,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      status: status ?? this.status,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      preferences: preferences ?? this.preferences,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Auth Result Model
class AuthResult {
  final bool success;
  final User? user;
  final String? token;
  final String? refreshToken;
  final String? message;

  AuthResult({
    required this.success,
    this.user,
    this.token,
    this.refreshToken,
    this.message,
  });

  factory AuthResult.success({
    required User user,
    required String token,
    String? refreshToken,
  }) {
    return AuthResult(
      success: true,
      user: user,
      token: token,
      refreshToken: refreshToken,
    );
  }

  factory AuthResult.failure({required String message}) {
    return AuthResult(
      success: false,
      message: message,
    );
  }
}
