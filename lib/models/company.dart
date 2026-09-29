import 'package:audira_receipt/core/constants/app_constants.dart';

class Company {
  final int? id;
  final String name;
  final String tagline;
  final String address;
  final String phone;
  final String email;
  final String? logo;
  final String footerMessage;
  final String bankInfo;
  final String signerName;

  Company({
    this.id,
    required this.name,
    this.tagline = 'MULTIMEDIA DIGITAL',
    required this.address,
    required this.phone,
    required this.email,
    this.logo,
    this.footerMessage = 'Terima kasih atas kepercayaan Anda',
    this.bankInfo = '',
    this.signerName = '',
  });

  factory Company.defaultCompany() {
    return Company(
      id: 1,
      name: AppConstants.defaultCompanyName,
      tagline: 'MULTIMEDIA DIGITAL',
      address: AppConstants.defaultCompanyAddress,
      phone: AppConstants.defaultCompanyPhone,
      email: AppConstants.defaultCompanyEmail,
      footerMessage: 'Terima kasih atas kepercayaan Anda',
      bankInfo: 'BCA 8800123456 a/n PT AUDIRA',
      signerName: 'Kasir / Bendahara',
    );
  }

  Company copyWith({
    int? id,
    String? name,
    String? tagline,
    String? address,
    String? phone,
    String? email,
    String? logo,
    String? footerMessage,
    String? bankInfo,
    String? signerName,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logo: logo ?? this.logo,
      footerMessage: footerMessage ?? this.footerMessage,
      bankInfo: bankInfo ?? this.bankInfo,
      signerName: signerName ?? this.signerName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'tagline': tagline,
      'address': address,
      'phone': phone,
      'email': email,
      'logo': logo,
      'footer_message': footerMessage,
      'bank_info': bankInfo,
      'signer_name': signerName,
    };
  }

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'] as int?,
      name: map['name'] as String? ?? AppConstants.defaultCompanyName,
      tagline: map['tagline'] as String? ?? 'MULTIMEDIA DIGITAL',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      logo: map['logo'] as String?,
      footerMessage: map['footer_message'] as String? ?? 'Terima kasih atas kepercayaan Anda',
      bankInfo: map['bank_info'] as String? ?? '',
      signerName: map['signer_name'] as String? ?? '',
    );
  }
}
