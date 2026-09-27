import 'package:audira_receipt/core/constants/app_constants.dart';

class Company {
  final int? id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String? logo;

  Company({
    this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    this.logo,
  });

  factory Company.defaultCompany() {
    return Company(
      id: 1,
      name: AppConstants.defaultCompanyName,
      address: AppConstants.defaultCompanyAddress,
      phone: AppConstants.defaultCompanyPhone,
      email: AppConstants.defaultCompanyEmail,
    );
  }

  Company copyWith({
    int? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? logo,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logo: logo ?? this.logo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'logo': logo,
    };
  }

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'] as int?,
      name: map['name'] as String? ?? AppConstants.defaultCompanyName,
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      logo: map['logo'] as String?,
    );
  }
}
