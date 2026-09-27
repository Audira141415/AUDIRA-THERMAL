import 'package:audira_receipt/core/constants/app_constants.dart';

class AppSettings {
  final int? id;
  final String receiptPrefix;
  final int lastReceiptNumber;
  final String paperSize;
  final bool autoCut;
  final bool printLogo;
  final int printDensity;
  final String characterSize;

  AppSettings({
    this.id,
    this.receiptPrefix = AppConstants.defaultReceiptPrefix,
    this.lastReceiptNumber = 0,
    this.paperSize = AppConstants.paper58mm,
    this.autoCut = true,
    this.printLogo = false,
    this.printDensity = 2,
    this.characterSize = 'normal',
  });

  factory AppSettings.defaultSettings() {
    return AppSettings(
      id: 1,
      receiptPrefix: AppConstants.defaultReceiptPrefix,
      lastReceiptNumber: 0,
      paperSize: AppConstants.paper58mm,
      autoCut: true,
      printLogo: false,
      printDensity: 2,
      characterSize: 'normal',
    );
  }

  AppSettings copyWith({
    int? id,
    String? receiptPrefix,
    int? lastReceiptNumber,
    String? paperSize,
    bool? autoCut,
    bool? printLogo,
    int? printDensity,
    String? characterSize,
  }) {
    return AppSettings(
      id: id ?? this.id,
      receiptPrefix: receiptPrefix ?? this.receiptPrefix,
      lastReceiptNumber: lastReceiptNumber ?? this.lastReceiptNumber,
      paperSize: paperSize ?? this.paperSize,
      autoCut: autoCut ?? this.autoCut,
      printLogo: printLogo ?? this.printLogo,
      printDensity: printDensity ?? this.printDensity,
      characterSize: characterSize ?? this.characterSize,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receipt_prefix': receiptPrefix,
      'last_receipt_number': lastReceiptNumber,
      'paper_size': paperSize,
      'auto_cut': autoCut ? 1 : 0,
      'print_logo': printLogo ? 1 : 0,
      'print_density': printDensity,
      'character_size': characterSize,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: map['id'] as int?,
      receiptPrefix: map['receipt_prefix'] as String? ?? AppConstants.defaultReceiptPrefix,
      lastReceiptNumber: map['last_receipt_number'] as int? ?? 0,
      paperSize: map['paper_size'] as String? ?? AppConstants.paper58mm,
      autoCut: (map['auto_cut'] as int? ?? 1) == 1,
      printLogo: (map['print_logo'] as int? ?? 0) == 1,
      printDensity: map['print_density'] as int? ?? 2,
      characterSize: map['character_size'] as String? ?? 'normal',
    );
  }
}
